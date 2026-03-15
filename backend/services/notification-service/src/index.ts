import { createServer, env } from "@taxiya/shared";

const start = async () => {
  const app = await createServer("notification-service");

  app.post("/notifications/push", async (request) => {
    const body = request.body as Record<string, unknown>;
    app.log.info({ body }, "Queue push notification for FCM delivery");
    return { queued: true };
  });

  await app.listen({ host: env.HOST, port: 3006 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});

