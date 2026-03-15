import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import rateLimit from "@fastify/rate-limit";
import Fastify, { FastifyInstance } from "fastify";
import { config as loadEnv } from "dotenv";
import Redis from "ioredis";
import amqp, { ChannelModel } from "amqplib";
import { Pool } from "pg";
import { z } from "zod";

loadEnv();

const envSchema = z.object({
  NODE_ENV: z.string().default("development"),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default("0.0.0.0"),
  DATABASE_URL: z.string().default("postgresql://postgres:postgres@localhost:5432/taxiya"),
  REDIS_URL: z.string().default("redis://localhost:6379"),
  RABBITMQ_URL: z.string().default("amqp://guest:guest@localhost:5672"),
  JWT_SECRET: z.string().default("taxiya-secret"),
  POTOSI_CENTER_LAT: z.coerce.number().default(-19.5836),
  POTOSI_CENTER_LNG: z.coerce.number().default(-65.7531),
  POTOSI_RADIUS_METERS: z.coerce.number().default(15000)
});

export const env = envSchema.parse(process.env);

export const db = new Pool({
  connectionString: env.DATABASE_URL,
  max: 20
});

export const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  lazyConnect: true
});

let mqConnectionPromise: Promise<ChannelModel> | undefined;

export const getRabbit = async (): Promise<ChannelModel> => {
  if (!mqConnectionPromise) {
    mqConnectionPromise = amqp.connect(env.RABBITMQ_URL);
  }
  return mqConnectionPromise;
};

export const TOPICS = {
  tripRequested: "trip.requested",
  tripAssigned: "trip.assigned",
  tripStarted: "trip.started",
  tripCompleted: "trip.completed",
  driverLocation: "driver.location",
  notificationPush: "notification.push"
} as const;

export const createServer = async (serviceName: string): Promise<FastifyInstance> => {
  const app = Fastify({
    logger: {
      level: env.NODE_ENV === "production" ? "info" : "debug",
      base: { service: serviceName }
    }
  });

  await app.register(cors, { origin: true });
  await app.register(rateLimit, { max: 200, timeWindow: "1 minute" });
  await app.register(jwt, { secret: env.JWT_SECRET });

  app.get("/health", async () => ({ ok: true, service: serviceName }));

  return app;
};

export const assertWithinPotosi = (lat: number, lng: number): boolean => {
  const toRad = (value: number) => (value * Math.PI) / 180;
  const earthRadius = 6371000;
  const dLat = toRad(lat - env.POTOSI_CENTER_LAT);
  const dLng = toRad(lng - env.POTOSI_CENTER_LNG);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(env.POTOSI_CENTER_LAT)) *
      Math.cos(toRad(lat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const distance = 2 * earthRadius * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return distance <= env.POTOSI_RADIUS_METERS;
};

export const publishEvent = async <T>(routingKey: string, payload: T) => {
  const connection = await getRabbit();
  const channel = await connection.createChannel();
  const exchange = "taxiya.events";

  await channel.assertExchange(exchange, "topic", { durable: true });
  channel.publish(exchange, routingKey, Buffer.from(JSON.stringify(payload)), {
    persistent: true,
    contentType: "application/json"
  });
};

export const registerJwtGuard = (app: FastifyInstance) => {
  app.decorate("authenticate", async (request: any, reply: any) => {
    try {
      await request.jwtVerify();
    } catch (error) {
      reply.code(401).send({ message: "Unauthorized", error });
    }
  });
};

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: unknown, reply: unknown) => Promise<void>;
  }
}

