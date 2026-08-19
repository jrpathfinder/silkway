# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Scaffolding for a Central Asia restaurant delivery platform (single Moscow location for MVP). Three apps share one npm workspace root: a NestJS API, a minimal TS web admin, and a Flutter customer app shell.

## Commands

Run from the repo root unless noted.

```bash
npm install                                    # installs all workspaces
cp apps/api/.env.example apps/api/.env         # first-time API setup
docker compose -f infra/docker-compose.yml up -d  # local Postgres + Redis

npm --workspace apps/api run start:dev         # API dev server (ts-node-dev, port 3000)
npm run api:build                              # tsc build -> apps/api/dist
npm run api:test                               # jest --runInBand, all apps/api/src/**/*.spec.ts
npm --workspace apps/api test -- orders.service.spec.ts   # single test file
npm --workspace apps/api test -- -t "idempotent"          # single test by name

npm run admin:build                            # tsc build for apps/admin
npm run contracts:build                        # build packages/contracts
```

There is no lint script configured yet in any workspace. The Flutter app (`apps/customer`) is a bare `flutter create` shell with standard `flutter run` / `flutter test` commands; it has no CI wiring here.

The API auto-applies `apps/api/src/database/schema.sql` on boot when `DATABASE_URL` is set (see below) — no separate migration step.

## Architecture

**Modular monolith, not microservices.** One NestJS process (`apps/api`), one Postgres database. This is a deliberate MVP choice (see [docs/adr/001-modular-monolith.md](docs/adr/001-modular-monolith.md)): modules must not import each other's internal classes — cross-module calls go through a module's exported service/controller only. The domain model is `Brand -> City -> Location` from day one so adding Moscow locations later doesn't require a schema change.

**Module map** (`apps/api/src/modules/*`): `health`, `locations`, `catalog`, `auth`, `orders`, `integrations`. Each is a self-contained Nest module (`*.module.ts` + `*.controller.ts` + `*.service.ts`). `app.module.ts` wires them together.

**Database is optional at runtime.** `DatabaseService` (`apps/api/src/database/database.service.ts`) only creates a `pg.Pool` if `DATABASE_URL` is set; otherwise `database.enabled` is `false`. Services that read persistent data (currently `CatalogService`) branch on `this.database.enabled` and fall back to hardcoded in-memory fixtures — this lets tests and quick local runs work without Postgres. When adding a DB-backed feature, follow this same fallback pattern rather than making the DB a hard dependency.

**`OrdersService` is still fully in-memory** (`Map`-based, not yet wired to the `order_header`/`order_event`/`outbox_event` tables already defined in `schema.sql`). The schema is ahead of the service implementation — don't assume orders are persisted just because the tables exist.

**External providers are behind ports, not called directly.** `apps/api/src/modules/integrations/ports/*.port.ts` defines abstract classes (`PaymentProvider`, `DeliveryProvider`, `MarketplacePort`) that domain code depends on. `integrations.module.ts` binds each port to a concrete provider via Nest's `useClass` (currently only `MockPaymentProvider` is implemented; delivery/marketplace providers are stubs). This is ADR-002 (see [docs/adr/002-provider-adapters.md](docs/adr/002-provider-adapters.md)): real ЮKassa/Yandex Delivery/Yandex Eda integrations get added as new provider classes bound in the same place, without touching domain services. When testing domain services, inject a fake implementing the port interface directly (see `orders.service.spec.ts`'s `TestPaymentProvider`) rather than mocking a library.

**Server-side price snapshots.** `OrdersService.create` always re-fetches the catalog and recomputes item/modifier prices server-side — client-submitted prices are never trusted. `Idempotency-Key` is honored via an in-memory key→orderId map. Any change to order creation needs to preserve both of these invariants.

**Auth is a dev-only stub.** `AuthService.verifyOtp` accepts hardcoded code `0000` outside `NODE_ENV=production` and returns static dev tokens; there's no real session/JWT issuance yet. Treat anything under `modules/auth` as scaffolding to be replaced, not a pattern to copy.

**API base path is `/v1`** (set globally in `main.ts`), with global `ValidationPipe({ whitelist: true, transform: true })`. See [docs/api.md](docs/api.md) for the intended public/webhook/admin endpoint contract — several listed endpoints (e.g. checkout, webhooks) are not fully implemented yet.

**`packages/contracts`** holds shared TS types (e.g. `Location`, `OrderStatus`) meant to be consumed by both `apps/api` and `apps/admin`; keep API DTOs and admin types in sync with it rather than redefining shapes locally.

**`apps/admin`** is presently a single hardcoded `index.ts` rendering static mock order data into the DOM — no framework, no API calls yet, no build tooling beyond `tsc`.

## Domain flow (direct orders)

Customer selects location → server-priced cart snapshot → order created `PENDING_PAYMENT` with idempotency key → payment adapter creates checkout → verified webhook moves order to `PAID` → restaurant accepts → delivery adapter creates delivery → provider events update status → outbox/reconciliation retries unfinished external calls. Full detail in [docs/architecture.md](docs/architecture.md) (Russian).

## Non-obvious conventions

- Money is stored/queried as integer minor units (`price_minor`, kopecks) in Postgres but exposed as `priceRub` (float rubles) in API/service types — conversion happens in the service layer (see `CatalogService.getForLocation`).
- Row types from `pg` queries use `snake_case` (matching SQL columns); mapped API-facing types use `camelCase`. Keep that boundary at the service layer, not in controllers.
- This is pre-production scaffolding, not legal advice — see the "Important" section in [README.md](README.md) and [docs/security-and-compliance-ru.md](docs/security-and-compliance-ru.md) before treating any payment/fiscalization/consent behavior as production-ready.
