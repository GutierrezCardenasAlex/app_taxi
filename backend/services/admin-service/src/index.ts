import { createServer, db, env, registerJwtGuard } from "@taxiya/shared";

const start = async () => {
  const app = await createServer("admin-service");
  registerJwtGuard(app);

  app.get("/admin/drivers", { preHandler: [app.authenticate] }, async () => {
    const result = await db.query(
      `SELECT d.id, d.status, d.rating, u.full_name, u.phone_number, v.plate_number, v.make, v.model
       FROM drivers d
       JOIN users u ON u.id = d.user_id
       JOIN vehicles v ON v.id = d.vehicle_id
       ORDER BY d.updated_at DESC`
    );
    return result.rows;
  });

  app.get("/admin/trips", { preHandler: [app.authenticate] }, async () => {
    const result = await db.query(`SELECT * FROM trips ORDER BY requested_at DESC LIMIT 200`);
    return result.rows;
  });

  app.get("/admin/active-trips", { preHandler: [app.authenticate] }, async () => {
    const result = await db.query(`SELECT * FROM trips WHERE status IN ('accepted', 'arriving', 'in_progress')`);
    return result.rows;
  });

  app.get("/admin/stats", { preHandler: [app.authenticate] }, async () => {
    const [drivers, trips, activeTrips] = await Promise.all([
      db.query(`SELECT COUNT(*)::int AS count FROM drivers WHERE status = 'available'`),
      db.query(`SELECT COUNT(*)::int AS count FROM trips WHERE requested_at >= NOW() - INTERVAL '1 day'`),
      db.query(`SELECT COUNT(*)::int AS count FROM trips WHERE status IN ('accepted', 'arriving', 'in_progress')`)
    ]);

    return {
      availableDrivers: drivers.rows[0].count,
      tripsLast24h: trips.rows[0].count,
      activeTrips: activeTrips.rows[0].count
    };
  });

  await app.listen({ host: env.HOST, port: 3007 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});

