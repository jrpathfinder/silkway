# Central Asia Restaurant Delivery Platform

Scalable starter monorepo for the Central Asia restaurant delivery app in Moscow.

## Repository layout

- `apps/api` — NestJS modular backend starter.
- `apps/customer` — Flutter iOS/Android customer app shell.
- `apps/admin` — responsive web-admin starter.
- `packages/contracts` — shared API/domain contract examples.
- `infra` — local PostgreSQL/Redis infrastructure.
- `docs` — architecture, ADRs, security, and Russian compliance checklist.

## Quick start

```bash
cp apps/api/.env.example apps/api/.env
npm install
docker compose -f infra/docker-compose.yml up -d
npm --workspace apps/api run start:dev
```

On startup, the API creates the PostgreSQL tables and seeds a small Central Asia menu. The API exposes health and catalog endpoints at `http://localhost:3000`:

- `GET /v1/health`
- `GET /v1/locations`
- `GET /v1/locations/ca-moscow-1/catalog`

The catalog is read from PostgreSQL when `DATABASE_URL` is configured. Without it, development tests use an in-memory fallback.

The external providers are intentionally adapter-based. The default development implementations are safe mocks; production credentials and contracts must be configured before enabling payments, fiscalization, Yandex Eda, or delivery.

## Important

This repository contains technical scaffolding, not legal advice. Before production, confirm the restaurant legal entity, online cash register/ОФД, consent texts, personal-data inventory, hosting boundary, payment-provider agreement, and Yandex partner access with Russian legal and accounting specialists.
