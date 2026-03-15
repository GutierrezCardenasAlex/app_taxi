import { assertWithinPotosi, createServer, db, env, publishEvent, redis, registerJwtGuard, TOPICS } from "@taxiya/shared";
import { z } from "zod";

const tripRequestSchema = z.object({
  pickupAddress: z.string(),
  dropoffAddress: z.string(),
  pickupLat: z.number(),
  pickupLng: z.number(),
  dropoffLat: z.number(),
  dropoffLng: z.number(),
  pickupNotes: z.string().optional(),
  dropoffNotes: z.string().optional(),
});

const start = async () => {
  const app = await createServer("trip-service");
  registerJwtGuard(app);
  await redis.connect();

  app.post("/trip/request", { preHandler: [app.authenticate] }, async (request, reply) => {
    const body = tripRequestSchema.parse(request.body);
    const passengerId = (request.user as { sub: string }).sub;

    if (!assertWithinPotosi(body.pickupLat, body.pickupLng) || !assertWithinPotosi(body.dropoffLat, body.dropoffLng)) {
      return reply.code(400).send({ message: "Taxi Ya only operates inside Potosi, Bolivia" });
    }

    const result = await db.query(
      `INSERT INTO trips (
        passenger_id, status, pickup_address, dropoff_address, pickup_location, dropoff_location, estimated_fare, pickup_notes, dropoff_notes
      )
      VALUES (
        $1, 'requested', $2, $3,
        ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography,
        ST_SetSRID(ST_MakePoint($6, $7), 4326)::geography,
        10 + ST_Distance(
          ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography,
          ST_SetSRID(ST_MakePoint($6, $7), 4326)::geography
        ) / 1000 * 3,
        $8, $9
      )
      RETURNING *`,
      [passengerId, body.pickupAddress, body.dropoffAddress, body.pickupLng, body.pickupLat, body.dropoffLng, body.dropoffLat, body.pickupNotes ?? null, body.dropoffNotes ?? null],
    );

    await db.query(
      `INSERT INTO trip_events (trip_id, event_type, payload) VALUES ($1, 'requested', $2::jsonb)`,
      [result.rows[0].id, JSON.stringify({ pickupAddress: body.pickupAddress, dropoffAddress: body.dropoffAddress })],
    );

    await publishEvent(TOPICS.tripRequested, result.rows[0]);
    reply.code(201).send(result.rows[0]);
  });

  app.get("/trip/history", { preHandler: [app.authenticate] }, async (request) => {
    const passengerId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `SELECT * FROM trips WHERE passenger_id = $1 ORDER BY requested_at DESC LIMIT 50`,
      [passengerId],
    );
    return result.rows;
  });

  app.get("/trip/status/:tripId", { preHandler: [app.authenticate] }, async (request) => {
    const params = z.object({ tripId: z.string().uuid() }).parse(request.params);
    const result = await db.query(`SELECT * FROM trips WHERE id = $1`, [params.tripId]);
    return result.rows[0];
  });

  app.get("/trip/current", { preHandler: [app.authenticate] }, async (request) => {
    const passengerId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `SELECT * FROM trips
       WHERE passenger_id = $1
         AND status IN ('requested', 'assigned', 'accepted', 'arriving', 'in_progress')
       ORDER BY requested_at DESC
       LIMIT 1`,
      [passengerId],
    );
    return result.rows[0] ?? null;
  });

  app.get("/trip/events/:tripId", { preHandler: [app.authenticate] }, async (request) => {
    const params = z.object({ tripId: z.string().uuid() }).parse(request.params);
    const result = await db.query(
      `SELECT * FROM trip_events WHERE trip_id = $1 ORDER BY created_at DESC LIMIT 50`,
      [params.tripId],
    );
    return result.rows;
  });

  app.post("/trip/start", { preHandler: [app.authenticate] }, async (request) => {
    const body = z.object({ tripId: z.string().uuid() }).parse(request.body);
    const result = await db.query(
      `UPDATE trips SET status = 'in_progress', started_at = NOW(), version = version + 1 WHERE id = $1 RETURNING *`,
      [body.tripId],
    );
    await db.query(`INSERT INTO trip_events (trip_id, event_type, payload) VALUES ($1, 'started', '{}'::jsonb)`, [body.tripId]);
    await publishEvent(TOPICS.tripStarted, result.rows[0]);
    await publishEvent(TOPICS.tripUpdated, result.rows[0]);
    await redis.publish(`events:trip:${body.tripId}`, JSON.stringify({ type: "trip.started", trip: result.rows[0] }));
    return result.rows[0];
  });

  app.post("/trip/end", { preHandler: [app.authenticate] }, async (request) => {
    const body = z.object({ tripId: z.string().uuid(), finalFare: z.number().positive() }).parse(request.body);
    const result = await db.query(
      `UPDATE trips
       SET status = 'completed', completed_at = NOW(), final_fare = $2, version = version + 1
       WHERE id = $1
       RETURNING *`,
      [body.tripId, body.finalFare],
    );
    await db.query(`INSERT INTO trip_events (trip_id, event_type, payload) VALUES ($1, 'completed', $2::jsonb)`, [body.tripId, JSON.stringify({ finalFare: body.finalFare })]);
    await publishEvent(TOPICS.tripCompleted, result.rows[0]);
    await publishEvent(TOPICS.tripUpdated, result.rows[0]);
    await redis.publish(`events:trip:${body.tripId}`, JSON.stringify({ type: "trip.completed", trip: result.rows[0] }));
    return result.rows[0];
  });

  await app.listen({ host: env.HOST, port: 3003 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
