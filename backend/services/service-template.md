# Service Template

Each service is a standalone Fastify application with:

- `/health`
- JWT middleware when needed
- PostgreSQL for source-of-truth operations
- Redis for live/ephemeral state
- RabbitMQ for asynchronous events

