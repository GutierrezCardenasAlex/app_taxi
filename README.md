# Taxi Ya

Taxi Ya is a ride-hailing platform for Potosi, Bolivia, designed to start small and scale from 10 to 10,000 drivers with a low-cost microservices architecture.

## Monorepo layout

- `backend/`: Fastify-based microservices, shared packages, and PostGIS schema.
- `mobile/`: Flutter passenger and driver apps using Clean Architecture and Riverpod.
- `admin-web/`: React + Vite admin dashboard with OpenStreetMap and WebSocket updates.
- `infra/`: Docker Compose and Kubernetes manifests.
- `docs/`: Architecture, scaling, and operational notes.

## Core architecture

- API gateway for rate limiting, auth forwarding, and service routing.
- Independent stateless services for auth, drivers, trips, dispatch, location, notifications, and admin APIs.
- PostgreSQL + PostGIS for persistent transactional and geospatial data.
- Redis for active driver state, live locations, dispatch coordination, and WebSocket session metadata.
- RabbitMQ for event-driven communication between services.
- WebSockets for 5-second driver telemetry and live trip/admin updates.
- OpenStreetMap for passenger, driver, and admin mapping.
- FCM for push notifications.

## Geo restriction

All trip requests and driver operations are restricted to a 15 km radius from Potosi city center:

- Latitude: `-19.5836`
- Longitude: `-65.7531`
- Radius: `15000m`

## Quick start

1. Install Node.js 20+, npm 10+, Flutter 3.24+, and Docker.
2. Copy `.env.example` values into service-specific `.env` files if needed.
3. Start infrastructure:

```bash
docker compose -f infra/docker/docker-compose.yml up -d
```

4. Install JavaScript dependencies:

```bash
npm install
```

5. Run backend services:

```bash
npm run dev -w @taxiya/gateway-api
```

6. Run the admin panel:

```bash
npm run dev -w admin-web
```

7. Run Flutter apps from `mobile/passenger_app` and `mobile/driver_app`.

## Production deployment

- Local and low-cost bootstrap: Docker Compose on a single VM.
- Growth phase: Kubernetes with horizontal pod autoscaling for stateless services.
- Database: managed PostgreSQL/PostGIS or a replicated cluster.
- Cache/message broker: managed Redis and RabbitMQ where available.

See [docs/architecture.md](docs/architecture.md) and [infra/k8s/base](infra/k8s/base).

