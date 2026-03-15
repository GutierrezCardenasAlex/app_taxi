# Taxi Ya Architecture

## Service boundaries

- `gateway-api`: Entry point, JWT validation, rate limiting, request forwarding, public WebSocket ingress.
- `auth-service`: OTP flow, JWT issuance, passenger/driver/admin identities.
- `driver-service`: Driver profiles, vehicle records, availability state.
- `trip-service`: Trip lifecycle, history, fare, trip events, route persistence.
- `dispatch-service`: Nearest-driver search, offer fan-out, optimistic locking on assignment.
- `location-service`: Driver telemetry ingest, Redis live cache, trip tracking broadcast.
- `notification-service`: FCM push delivery, retries, dead-letter handling.
- `admin-service`: Dashboard APIs, live counters, monitoring endpoints.

## Scale path

### 10-100 drivers

- Single VM or managed container host.
- One PostgreSQL instance with daily backups.
- One Redis instance.
- One RabbitMQ node.

### 100-2,000 drivers

- Split services across multiple containers.
- Add Redis replica and RabbitMQ quorum queues.
- Move WebSocket-heavy location service to its own autoscaled tier.

### 2,000-10,000 drivers

- Kubernetes deployment with HPA on CPU and WebSocket connection count.
- Read replicas for trip/admin workloads.
- Partition `trip_tracking` and `driver_locations` by date if volume demands it.
- Use Redis geospatial indexes for hot-path reads while retaining PostGIS as source of truth.

## Dispatch model

1. Passenger submits pickup/dropoff inside the Potosi radius.
2. `dispatch-service` queries nearby available drivers from Redis and PostGIS.
3. Candidate drivers receive an FCM notification and a WebSocket event.
4. The first valid acceptance wins through a single transaction with row locking/version check.
5. `trip-service` emits events consumed by location, notification, and admin services.

## Reliability

- Services are stateless and horizontally scalable.
- RabbitMQ decouples trip, analytics, and notification flows.
- Redis stores only ephemeral state; PostgreSQL remains the system of record.
- Health endpoints, structured logs, and idempotent consumers reduce operational risk.

