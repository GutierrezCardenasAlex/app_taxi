import proxy from "@fastify/http-proxy";
import { createServer, env } from "@taxiya/shared";

const start = async () => {
  const app = await createServer("gateway-api");
  const authUrl = process.env.AUTH_SERVICE_URL ?? "http://localhost:3001";
  const driverUrl = process.env.DRIVER_SERVICE_URL ?? "http://localhost:3002";
  const tripUrl = process.env.TRIP_SERVICE_URL ?? "http://localhost:3003";
  const dispatchUrl = process.env.DISPATCH_SERVICE_URL ?? "http://localhost:3004";
  const locationUrl = process.env.LOCATION_SERVICE_URL ?? "http://localhost:3005";
  const notificationUrl = process.env.NOTIFICATION_SERVICE_URL ?? "http://localhost:3006";
  const adminUrl = process.env.ADMIN_SERVICE_URL ?? "http://localhost:3007";

  const routes = [
    { prefix: "/auth", upstream: authUrl },
    { prefix: "/driver/location", upstream: locationUrl },
    { prefix: "/driver", upstream: driverUrl },
    { prefix: "/trip/accept", upstream: dispatchUrl },
    { prefix: "/trip", upstream: tripUrl },
    { prefix: "/dispatch", upstream: dispatchUrl },
    { prefix: "/location", upstream: locationUrl },
    { prefix: "/notifications", upstream: notificationUrl },
    { prefix: "/admin", upstream: adminUrl }
  ];

  for (const route of routes) {
    await app.register(proxy, {
      upstream: route.upstream,
      prefix: route.prefix,
      rewritePrefix: route.prefix
    });
  }

  await app.listen({ host: env.HOST, port: env.PORT });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
