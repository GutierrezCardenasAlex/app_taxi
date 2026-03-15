import { createServer, db, env } from "@taxiya/shared";
import { z } from "zod";

const otpStore = new Map<string, string>();

const start = async () => {
  const app = await createServer("auth-service");

  app.post("/auth/send-otp", async (request, reply) => {
    const body = z.object({ phoneNumber: z.string().min(8).max(20), role: z.enum(["passenger", "driver"]).default("passenger") }).parse(request.body);
    const otp = env.NODE_ENV === "production" ? String(Math.floor(100000 + Math.random() * 900000)) : "123456";
    otpStore.set(body.phoneNumber, otp);

    await db.query(
      `INSERT INTO users (phone_number, role)
       VALUES ($1, $2)
       ON CONFLICT (phone_number) DO UPDATE SET updated_at = NOW()`,
      [body.phoneNumber, body.role]
    );

    reply.send({ success: true, otp: env.NODE_ENV === "production" ? undefined : otp });
  });

  app.post("/auth/verify-otp", async (request, reply) => {
    const body = z.object({ phoneNumber: z.string(), otp: z.string().length(6) }).parse(request.body);
    const expected = otpStore.get(body.phoneNumber);

    if (expected !== body.otp) {
      return reply.code(401).send({ message: "Invalid OTP" });
    }

    const result = await db.query(`SELECT id, role, phone_number FROM users WHERE phone_number = $1`, [body.phoneNumber]);
    const user = result.rows[0];
    const token = await reply.jwtSign({ sub: user.id, role: user.role, phoneNumber: user.phone_number });

    otpStore.delete(body.phoneNumber);
    reply.send({ token, user });
  });

  await app.listen({ host: env.HOST, port: 3001 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});

