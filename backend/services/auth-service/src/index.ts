import { createServer, db, env, registerJwtGuard } from "@taxiya/shared";
import { z } from "zod";

const otpStore = new Map<string, string>();

const settingsSchema = z.object({
  emergencyContactName: z.string().optional(),
  emergencyContactPhone: z.string().optional(),
  preferredRideType: z.enum(["economico", "rapido"]).optional(),
  shareTripDefault: z.boolean().optional(),
  notificationsEnabled: z.boolean().optional(),
});

const start = async () => {
  const app = await createServer("auth-service");
  registerJwtGuard(app);

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

    const result = await db.query(`SELECT id, role, phone_number, full_name FROM users WHERE phone_number = $1`, [body.phoneNumber]);
    const user = result.rows[0];
    const token = await reply.jwtSign({ sub: user.id, role: user.role, phoneNumber: user.phone_number });

    otpStore.delete(body.phoneNumber);
    reply.send({ token, user });
  });

  app.get("/auth/me", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const result = await db.query(
      `SELECT u.id, u.phone_number, u.role, u.full_name,
              s.emergency_contact_name, s.emergency_contact_phone, s.preferred_ride_type,
              s.share_trip_default, s.notifications_enabled
       FROM users u
       LEFT JOIN user_settings s ON s.user_id = u.id
       WHERE u.id = $1`,
      [userId],
    );
    return result.rows[0];
  });

  app.put("/auth/profile", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const body = z.object({ fullName: z.string().min(2).max(120) }).parse(request.body);
    const result = await db.query(
      `UPDATE users SET full_name = $2, updated_at = NOW() WHERE id = $1 RETURNING id, phone_number, role, full_name`,
      [userId, body.fullName],
    );
    return result.rows[0];
  });

  app.put("/auth/settings", { preHandler: [app.authenticate] }, async (request) => {
    const userId = (request.user as { sub: string }).sub;
    const body = settingsSchema.parse(request.body);
    const result = await db.query(
      `INSERT INTO user_settings (
        user_id, emergency_contact_name, emergency_contact_phone, preferred_ride_type, share_trip_default, notifications_enabled, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        emergency_contact_name = EXCLUDED.emergency_contact_name,
        emergency_contact_phone = EXCLUDED.emergency_contact_phone,
        preferred_ride_type = EXCLUDED.preferred_ride_type,
        share_trip_default = EXCLUDED.share_trip_default,
        notifications_enabled = EXCLUDED.notifications_enabled,
        updated_at = NOW()
      RETURNING *`,
      [
        userId,
        body.emergencyContactName ?? null,
        body.emergencyContactPhone ?? null,
        body.preferredRideType ?? "economico",
        body.shareTripDefault ?? false,
        body.notificationsEnabled ?? true,
      ],
    );
    return result.rows[0];
  });

  await app.listen({ host: env.HOST, port: 3001 });
};

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
