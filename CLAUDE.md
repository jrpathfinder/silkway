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

**Module map** (`apps/api/src/modules/*`): `health`, `locations`, `catalog`, `auth`, `admin`, `orders`, `integrations`. Each is a self-contained Nest module (`*.module.ts` + `*.controller.ts` + `*.service.ts`). `app.module.ts` wires them together.

**Database is optional at runtime.** `DatabaseService` (`apps/api/src/database/database.service.ts`) only creates a `pg.Pool` if `DATABASE_URL` is set; otherwise `database.enabled` is `false`. Services that read persistent data (currently `CatalogService`) branch on `this.database.enabled` and fall back to hardcoded in-memory fixtures — this lets tests and quick local runs work without Postgres. When adding a DB-backed feature, follow this same fallback pattern rather than making the DB a hard dependency.

**`OrdersService` is still fully in-memory** (`Map`-based, not yet wired to the `order_header`/`order_event`/`outbox_event` tables already defined in `schema.sql`). The schema is ahead of the service implementation — don't assume orders are persisted just because the tables exist.

**External providers are behind ports, not called directly.** `apps/api/src/modules/integrations/ports/*.port.ts` defines abstract classes (`PaymentProvider`, `DeliveryProvider`, `MarketplacePort`, `SmsProvider`) that domain code depends on. `integrations.module.ts` binds each port to a concrete provider via Nest's `useClass` (`PaymentProvider` is hardcoded to `MockPaymentProvider`; `SmsProvider` switches on `SMS_PROVIDER` env var between `MockSmsProvider` — logs the code instead of sending it — and `SmsRuProvider`, which is a real, working [sms.ru](https://sms.ru) integration gated behind `SMS_RU_API_ID`; delivery/marketplace providers are still stubs). This is ADR-002 (see [docs/adr/002-provider-adapters.md](docs/adr/002-provider-adapters.md)): real ЮKassa/Yandex Delivery/Yandex Eda integrations get added as new provider classes bound in the same place, without touching domain services. When testing domain services, inject a fake implementing the port interface directly (see `orders.service.spec.ts`'s `TestPaymentProvider`, `auth.service.spec.ts`'s `TestSmsProvider`) rather than mocking a library.

**Server-side price snapshots.** `OrdersService.create` always re-fetches the catalog and recomputes item/modifier prices server-side — client-submitted prices are never trusted. `Idempotency-Key` is honored via an in-memory key→orderId map. Any change to order creation needs to preserve both of these invariants.

**OTP is real, session issuance is still a stub.** `OtpStore` (`apps/api/src/modules/auth/otp-store.service.ts`) generates a random 6-digit code per request, hashes it (`OTP_HASH_SECRET`) with a TTL (`OTP_TTL_SECONDS`), rate-limits resends (30s cooldown, 10/day per phone) and verify attempts (5 tries), all in an in-process `Map` — fine for a single instance, but needs moving to the already-provisioned Redis (`REDIS_URL`) before running more than one API instance or across restarts. `AuthService.verifyOtp` checks the real stored code — there is no hardcoded bypass code anymore. What's still a stub: successful verification returns static `dev-access-token`/`dev-refresh-token` strings, not a real session/JWT, and there's no customer id in the response (client uses the phone number instead — see ADR-003 in the Flutter repo).

**API base path is `/v1`** (set globally in `main.ts`), with global `ValidationPipe({ whitelist: true, transform: true })`. See [docs/api.md](docs/api.md) for the intended public/webhook/admin endpoint contract — several listed endpoints (e.g. checkout, webhooks) are not fully implemented yet.

**`packages/contracts`** holds shared TS types (e.g. `Location`, `OrderStatus`) meant to be consumed by both `apps/api` and `apps/admin`; keep API DTOs and admin types in sync with it rather than redefining shapes locally.

**`apps/admin`** is presently a single hardcoded `index.ts` rendering static mock order data into the DOM — no framework, no API calls yet, no build tooling beyond `tsc`.

## Domain flow (direct orders)

Customer selects location → server-priced cart snapshot → order created `PENDING_PAYMENT` with idempotency key → payment adapter creates checkout → verified webhook moves order to `PAID` → restaurant accepts → delivery adapter creates delivery → provider events update status → outbox/reconciliation retries unfinished external calls. Full detail in [docs/architecture.md](docs/architecture.md) (Russian).

## Linear sync

FR/NFR backlog is tracked in Linear, workspace `silkway`, team `Silkway` (key `SIL`), split across two projects: `SilkWayPlatform` (backend/platform) and `SilkWayIOS` (Flutter mobile, both iOS and Android). Whenever doing coding work against one of these tracked epics:

- Before starting, find the matching Linear issue (`list_issues` / search by title) rather than re-deriving scope from scratch.
- When you start substantive work on an issue still in `Backlog`, move it to `In Progress`.
- When a meaningful chunk of work lands (e.g. a PR is pushed), add a comment on the issue summarizing what shipped and what's still open against that issue's scope, linking the PR.
- Only move an issue to `Done` when its full scope is actually complete — these epics are broad (e.g. "search/filter" bundled with basic browsing), so a partial UI/asset change is progress, not completion. Default to `In Progress` + a comment rather than closing early.
- Never merge a PR without explicit user approval, regardless of Linear status.

**PR titles** follow `[SIL-XX] type: short description` — `SIL-XX` is the Linear issue the PR's work is scoped to (the one being moved to `In Progress`/commented on above), `type` is a conventional-commit-style prefix (`feat`, `fix`, `chore`, `refactor`, ...), and the description is a short imperative summary. When a PR spans multiple epics (e.g. a foundational scaffold), list every issue it actually touches as a comma-separated bracket: `[SIL-1, SIL-2, ...] type: short description` — only include issues with real corresponding work, not every issue that exists.

## Non-obvious conventions

- Money is stored/queried as integer minor units (`price_minor`, kopecks) in Postgres but exposed as `priceRub` (float rubles) in API/service types — conversion happens in the service layer (see `CatalogService.getForLocation`).
- Row types from `pg` queries use `snake_case` (matching SQL columns); mapped API-facing types use `camelCase`. Keep that boundary at the service layer, not in controllers.
- This is pre-production scaffolding, not legal advice — see the "Important" section in [README.md](README.md) and [docs/security-and-compliance-ru.md](docs/security-and-compliance-ru.md) before treating any payment/fiscalization/consent behavior as production-ready.
