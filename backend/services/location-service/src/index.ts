import websocket from "@fastify/websocket";
import { assertWithinPotosi, createServer, db, env, publishEvent, redis, registerJwtGuard, TOPICS } from "@taxiya/shared";
import { z } from "zod";

const locationSchema = z.object({
  driverId: z.string().uuid(),
  tripId: z.string().uuid().optional(),
  lat: z.number(),
  lng: z.number(),
  heading: z.number().optional(),
  speedKmh: z.number().optional(),
});

const start = async () => {
  const app = await createServer("location-service");
  registerJwtGuard(app);
  await app.register(websocket);
  await redis.connect();

  app.post("/driver/location", { preHandler: [app.authenticate] }, async (request, reply) => {
    const body = locationSchema.parse(request.body);
    if (!assertWithinPotosi(body.lat, body.lng)) {
      return reply.code(400).send({ message: "Location outside Potosi service area" });
    }

    await db.query(
      `INSERT INTO driver_locations (driver_id, location, heading, speed_kmh, recorded_at)
       VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography, $4, $5, NOW())
       ON CONFLICT (driver_id) DO UPDATE
       SET location = EXCLUDED.location, heading = EXCLUDED.heading, speed_kmh = EXCLUDED.speed_kmh, recorded_at = NOW()`,
      [body.driverId, body.lng, body.lat, body.heading ?? null, body.speedKmh ?? null],
    );

    await redis.geoadd("drivers:active", body.lng, body.lat, body.driverId);
    await redis.hset(`driver:${body.driverId}:location`, {
      lat: body.lat,
      lng: body.lng,
      heading: body.heading ?? 0,
      speedKmh: body.speedKmh ?? 0,
    });

    if (body.tripId) {
      await db.query(
        `INSERT INTO trip_tracking (trip_id, driver_id, location) VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography)`,
        [body.tripId, body.driverId, body.lng, body.lat],
      );
      await redis.publish(`events:trip:${body.tripId}`, JSON.stringify({ type: "driver.location", ...body }));
    }

    await redis.publish(`events:driver:${body.driverId}`, JSON.stringify({ type: "driver.location", ...body }));
    await publishEvent(TOPICS.driverLocation, body);
    return { success: true };
  });

  app.get("/location/driver/:driverId", async (request) => {
    const params = z.object({ driverId: z.string().uuid() }).parse(request.params);
    const result = await db.query(
      `SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, heading, speed_kmh, recorded_at
       FROM driver_locations
       WHERE driver_id = $1`,
      [params.driverId],
    );
    return result.rows[0] ?? null;
  });

  app.get("/ws/locations", { websocket: true }, (connection, request) => {
    const subscriber = redis.duplicate();
    const url = new URL(request.url, "http://localhost");
    const tripId = url.searchParams.get("tripId");
    const driverId = url.searchParams.get("driverId");
    const channels = [];

    if (tripId) channels.push(`events:trip:${tripId}`);
    if (driverId) channels.push(`events:driver:${driverId}`);
    if (channels.length === 0) channels.push("events:driver:*");

    subscriber.connect().then(async () => {
      if (channels.includes("events:driver:*")) {
        await subscriber.psubscribe("events:driver:*");
        subscriber.on("pmessage", (_, __, message) => connection.socket.send(message));
      } else {
        for (const channel of channels) {
          await subscriber.subscribe(channel);
        }
        subscriber.on("message", (_, message) => connection.socket.send(message));
      }
    });

    connection.socket.on("close", () => {
      subscriber.disconnect();
    });
  });

  await app.listen({ host: env.HOST, port: 3005 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
