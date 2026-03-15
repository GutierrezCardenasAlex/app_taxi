# Deployment Notes

## Low-cost starting point

- 1 application VM for all Node.js containers and the admin web.
- 1 managed PostgreSQL/PostGIS instance.
- 1 managed Redis instance.
- 1 RabbitMQ node or managed message queue equivalent.

## Kubernetes targets

- Put `gateway-api` and `location-service` behind the public load balancer.
- Keep `auth-service`, `driver-service`, `trip-service`, `dispatch-service`, `notification-service`, and `admin-service` internal.
- Use separate node pools only when WebSocket traffic justifies it.

## Cloud compatibility

- AWS: ECS/EKS, RDS PostgreSQL, ElastiCache Redis, Amazon MQ.
- Google Cloud: GKE, Cloud SQL PostgreSQL, Memorystore, self-managed RabbitMQ.
- DigitalOcean: Kubernetes, Managed PostgreSQL, Managed Redis, Droplets for RabbitMQ.
- Vultr: Kubernetes Engine, Managed Databases, Redis, VM-based RabbitMQ.

