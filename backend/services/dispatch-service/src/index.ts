import { consumeEvents, createServer, db, env, publishEvent, redis, registerJwtGuard, TOPICS } from "@taxiya/shared";
import { z } from "zod";

const offerTtlSeconds = 45;

const start = async () => {
  const app = await createServer("dispatch-service");
  registerJwtGuard(app);
  await redis.connect();

  app.post("/dispatch/find-nearest", { preHandler: [app.authenticate] }, async (request) => {
    const body = z.object({ lat: z.number(), lng: z.number() }).parse(request.body);
    const result = await db.query(
      `SELECT dl.driver_id, d.user_id
       FROM driver_locations dl
       JOIN drivers d ON d.id = dl.driver_id
       WHERE d.status = 'available'
         AND ST_DWithin(
           dl.location,
           ST_SetSRID(ST_MakePoint($1, $2),4326)::geography,
           3000
         )
       ORDER BY dl.location <-> ST_SetSRID(ST_MakePoint($1, $2),4326)::geography
       LIMIT 5`,
      [body.lng, body.lat],
    );
    return result.rows;
  });

  app.post("/trip/accept", { preHandler: [app.authenticate] }, async (request, reply) => {
    const body = z.object({ tripId: z.string().uuid(), driverId: z.string().uuid() }).parse(request.body);
    const client = await db.connect();

    try {
      await client.query("BEGIN");
      const trip = await client.query(`SELECT * FROM trips WHERE id = $1 FOR UPDATE`, [body.tripId]);
      if (!trip.rows[0] || !["requested", "assigned"].includes(trip.rows[0].status)) {
        await client.query("ROLLBACK");
        return reply.code(409).send({ message: "Trip already assigned or unavailable" });
      }

      const updated = await client.query(
        `UPDATE trips
         SET driver_id = $2, status = 'accepted', accepted_at = NOW(), version = version + 1
         WHERE id = $1
         RETURNING *`,
        [body.tripId, body.driverId],
      );

      await client.query(`UPDATE drivers SET status = 'busy', version = version + 1, updated_at = NOW() WHERE id = $1`, [body.driverId]);
      await client.query(`INSERT INTO trip_events (trip_id, event_type, payload) VALUES ($1, 'accepted', $2::jsonb)`, [body.tripId, JSON.stringify({ driverId: body.driverId })]);
      await client.query("COMMIT");

      await redis.del(`trip:${body.tripId}:offers`);
      await redis.set(`trip:${body.tripId}:driver`, body.driverId, "EX", 3600);
      await publishEvent(TOPICS.tripAssigned, updated.rows[0]);
      await publishEvent(TOPICS.tripUpdated, updated.rows[0]);
      await redis.publish(`events:trip:${body.tripId}`, JSON.stringify({ type: "trip.accepted", trip: updated.rows[0] }));
      await redis.publish(`events:driver:${body.driverId}`, JSON.stringify({ type: "trip.accepted", trip: updated.rows[0] }));

      return updated.rows[0];
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  });

  await consumeEvents("dispatch-service.trip-requested", [TOPICS.tripRequested], async (_, trip) => {
    const tripGeo = await db.query(
      `SELECT ST_X(pickup_location::geometry) AS pickup_lng, ST_Y(pickup_location::geometry) AS pickup_lat
       FROM trips WHERE id = $1`,
      [trip.id],
    );
    const pickupLng = tripGeo.rows[0]?.pickup_lng;
    const pickupLat = tripGeo.rows[0]?.pickup_lat;
    if (pickupLng == null || pickupLat == null) {
      return;
    }

    const result = await db.query(
      `SELECT dl.driver_id, d.user_id
       FROM driver_locations dl
       JOIN drivers d ON d.id = dl.driver_id
       WHERE d.status = 'available'
         AND ST_DWithin(
           dl.location,
           ST_SetSRID(ST_MakePoint($1, $2),4326)::geography,
           3000
         )
       ORDER BY dl.location <-> ST_SetSRID(ST_MakePoint($1, $2),4326)::geography
       LIMIT 5`,
      [pickupLng, pickupLat],
    );

    const driverIds = result.rows.map((row) => row.driver_id);
    if (driverIds.length === 0) {
      return;
    }

    await db.query(
      `UPDATE trips SET status = 'assigned', version = version + 1 WHERE id = $1`,
      [trip.id],
    );
    await db.query(
      `INSERT INTO trip_events (trip_id, event_type, payload) VALUES ($1, 'offer_sent', $2::jsonb)`,
      [trip.id, JSON.stringify({ driverIds })],
    );

    await redis.del(`trip:${trip.id}:offers`);
    for (const row of result.rows) {
      await redis.rpush(`trip:${trip.id}:offers`, row.driver_id);
      await redis.expire(`trip:${trip.id}:offers`, offerTtlSeconds);
      const payload = {
        type: "dispatch.offer",
        tripId: trip.id,
        driverId: row.driver_id,
        pickupAddress: trip.pickup_address,
        dropoffAddress: trip.dropoff_address,
        estimatedFare: trip.estimated_fare,
      };
      await redis.publish(`events:driver:${row.driver_id}`, JSON.stringify(payload));
      await publishEvent(TOPICS.dispatchOffer, payload);
    }
  });

  await app.listen({ host: env.HOST, port: 3004 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
