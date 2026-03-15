import { createServer, db, env, registerJwtGuard } from "@taxiya/shared";
import { z } from "zod";

const start = async () => {
  const app = await createServer("driver-service");
  registerJwtGuard(app);

  app.post("/driver/profile", { preHandler: [app.authenticate] }, async (request, reply) => {
    const body = z.object({
      licenseNumber: z.string(),
      plateNumber: z.string(),
      make: z.string(),
      model: z.string(),
      color: z.string(),
      year: z.number().optional(),
    }).parse(request.body);
    const userId = (request.user as { sub: string }).sub;

    const client = await db.connect();
    try {
      await client.query("BEGIN");
      const vehicle = await client.query(
        `INSERT INTO vehicles (plate_number, make, model, color, year)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (plate_number) DO UPDATE SET make = EXCLUDED.make, model = EXCLUDED.model, color = EXCLUDED.color, year = EXCLUDED.year
         RETURNING id`,
        [body.plateNumber, body.make, body.model, body.color, body.year ?? null],
      );
      const driver = await client.query(
        `INSERT INTO drivers (user_id, vehicle_id, license_number)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id) DO UPDATE SET vehicle_id = EXCLUDED.vehicle_id, license_number = EXCLUDED.license_number, updated_at = NOW()
         RETURNING *`,
        [userId, vehicle.rows[0].id, body.licenseNumber],
      );
      await client.query("COMMIT");
      reply.send(driver.rows[0]);
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  });

  app.post("/driver/status", { preHandler: [app.authenticate] }, async (request) => {
    const body = z.object({ status: z.enum(["offline", "available", "busy"]) }).parse(request.body);
    const userId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `UPDATE drivers SET status = $1, updated_at = NOW() WHERE user_id = $2 RETURNING *`,
      [body.status, userId],
    );
    return result.rows[0];
  });

  app.get("/driver/me", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `SELECT d.id AS driver_id, d.status, d.rating, d.license_number, d.user_id,
              u.full_name, u.phone_number,
              v.id AS vehicle_id, v.plate_number, v.make, v.model, v.color, v.year
       FROM drivers d
       JOIN vehicles v ON v.id = d.vehicle_id
       JOIN users u ON u.id = d.user_id
       WHERE d.user_id = $1`,
      [userId],
    );
    return result.rows[0];
  });

  app.get("/driver/offers", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const driver = await db.query(`SELECT id FROM drivers WHERE user_id = $1`, [userId]);
    if (!driver.rows[0]) return [];
    const offers = await db.query(
      `SELECT id, pickup_address, dropoff_address, status, estimated_fare, requested_at
       FROM trips
       WHERE driver_id IS NULL
         AND status = 'requested'
       ORDER BY requested_at DESC
       LIMIT 20`,
    );
    return offers.rows;
  });

  app.get("/driver/active-trip", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `SELECT t.*
       FROM trips t
       JOIN drivers d ON d.id = t.driver_id
       WHERE d.user_id = $1
         AND t.status IN ('accepted', 'arriving', 'in_progress')
       ORDER BY COALESCE(t.accepted_at, t.requested_at) DESC
       LIMIT 1`,
      [userId],
    );
    return result.rows[0] ?? null;
  });

  await app.listen({ host: env.HOST, port: 3002 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
