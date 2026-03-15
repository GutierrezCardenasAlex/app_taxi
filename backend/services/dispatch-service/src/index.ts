import { createServer, db, env, publishEvent, redis, registerJwtGuard, TOPICS } from "@taxiya/shared";
import { z } from "zod";

const start = async () => {
  const app = await createServer("dispatch-service");
  registerJwtGuard(app);
  await redis.connect();

  app.post("/dispatch/find-nearest", { preHandler: [app.authenticate] }, async (request) => {
    const body = z.object({ lat: z.number(), lng: z.number() }).parse(request.body);
    const result = await db.query(
      `SELECT driver_id
       FROM driver_locations
       WHERE ST_DWithin(
         location,
         ST_SetSRID(ST_MakePoint($1, $2),4326)::geography,
         3000
       )
       ORDER BY location <-> ST_SetSRID(ST_MakePoint($1, $2),4326)::geography
       LIMIT 5`,
      [body.lng, body.lat]
    );
    return result.rows;
  });

  app.post("/trip/accept", { preHandler: [app.authenticate] }, async (request, reply) => {
    const body = z.object({ tripId: z.string().uuid(), driverId: z.string().uuid() }).parse(request.body);
    const client = await db.connect();

    try {
      await client.query("BEGIN");
      const trip = await client.query(`SELECT * FROM trips WHERE id = $1 FOR UPDATE`, [body.tripId]);
      if (!trip.rows[0] || trip.rows[0].status !== "requested") {
        await client.query("ROLLBACK");
        return reply.code(409).send({ message: "Trip already assigned or unavailable" });
      }

      const updated = await client.query(
        `UPDATE trips
         SET driver_id = $2, status = 'accepted', accepted_at = NOW(), version = version + 1
         WHERE id = $1
         RETURNING *`,
        [body.tripId, body.driverId]
      );

      await client.query(`UPDATE drivers SET status = 'busy', version = version + 1, updated_at = NOW() WHERE id = $1`, [body.driverId]);
      await client.query("COMMIT");

      await redis.set(`trip:${body.tripId}:driver`, body.driverId, "EX", 3600);
      await publishEvent(TOPICS.tripAssigned, updated.rows[0]);

      return updated.rows[0];
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  });

  await app.listen({ host: env.HOST, port: 3004 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});

