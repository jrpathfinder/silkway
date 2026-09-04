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

**External providers are behind ports, not called directly.** `apps/api/src/modules/integrations/ports/*.port.ts` defines abstract classes (`PaymentProvider`, `DeliveryProvider`, `MarketplacePort`, `SmsProvider`) that domain code depends on. `integrations.module.ts` binds each port to a concrete provider via Nest's `useClass`, each switchable via an env var so mock stays the safe default: `PaymentProvider` switches on `PAYMENT_PROVIDER` between `MockPaymentProvider` and `YookassaPaymentProvider` (real ЮKassa REST API v3, gated behind `YOOKASSA_SHOP_ID`/`YOOKASSA_SECRET_KEY` — webhook verification lives in `apps/api/src/modules/orders/payment-webhook.controller.ts`, not in `integrations/`, because it needs `OrdersService`); `SmsProvider` switches on `SMS_PROVIDER` between `MockSmsProvider` — logs the code instead of sending it — and `SmsRuProvider`, a real [sms.ru](https://sms.ru) integration gated behind `SMS_RU_API_ID`. Delivery/marketplace providers are still stubs — no concrete class exists for either port yet, not even a mock, and neither is bound in `integrations.module.ts`. This is ADR-002 (see [docs/adr/002-provider-adapters.md](docs/adr/002-provider-adapters.md)): real Yandex Delivery/Yandex Eda integrations get added as new provider classes bound in the same place, without touching domain services. When testing domain services, inject a fake implementing the port interface directly (see `orders.service.spec.ts`'s `TestPaymentProvider`, `auth.service.spec.ts`'s `TestSmsProvider`) rather than mocking a library.

**Server-side price snapshots.** `OrdersService.create` always re-fetches the catalog and recomputes item/modifier prices server-side — client-submitted prices are never trusted. `Idempotency-Key` is honored via an in-memory key→orderId map. Any change to order creation needs to preserve both of these invariants.

**OTP is real, session issuance is still a stub.** `OtpStore` (`apps/api/src/modules/auth/otp-store.service.ts`) generates a random 6-digit code per request, hashes it (`OTP_HASH_SECRET`) with a TTL (`OTP_TTL_SECONDS`), and rate-limits resends (30s cooldown, 10/day per phone) and verify attempts (5 tries). Redis-backed when `REDIS_URL` is set (via `RedisService`, `apps/api/src/redis/`, same optional/`.enabled` shape as `DatabaseService`) — required once there's more than one API instance, since an in-process `Map` wouldn't share rate-limit state across instances or survive a restart; falls back to that in-process `Map` when Redis isn't configured (e.g. the unit tests, which construct `OtpStore` directly with no Redis). `AuthService.verifyOtp` checks the real stored code — there is no hardcoded bypass code anymore. What's still a stub: successful verification returns static `dev-access-token`/`dev-refresh-token` strings, not a real session/JWT, and there's no customer id in the response (client uses the phone number instead — see ADR-003 in the Flutter repo).

**Catalog-item photos are self-hosted.** `AdminUploadsController` (`apps/api/src/modules/admin/admin-uploads.controller.ts`) accepts a multipart upload (JPEG/PNG/WebP, 5MB max), writes it to `UPLOADS_DIR` (default `apps/api/uploads/`, gitignored) under a generated filename, and returns an absolute URL (`PUBLIC_BASE_URL` + `/uploads/<file>`) to store as `CatalogItem.imageUrl` — files are served back out by a static-assets mount in `main.ts`, not through a Nest route. `CatalogItem.imageUrl` itself is still just a plain string column; nothing stops it pointing at an external URL instead (the seeded menu currently mixes both — see `docs/wiki/*/integrations.md`). The admin panel's item form (`apps/admin/src/components/ItemsPanel.tsx`) offers both: a raw URL field and a file picker that uploads and fills the URL field in for you.

**Production container**: `apps/api/Dockerfile` (multi-stage, `node:20-alpine`, non-root, `HEALTHCHECK` against `/v1/health`) — build context is the repo root, since the install needs the root npm-workspaces lockfile even though the API only imports its own code at runtime. Not part of the default `docker compose up -d` (that command stays just Postgres+Redis, for local dev running the API directly via `start:dev`); run it with `docker compose --profile full up -d --build` from `infra/`, which also mounts a named volume onto the uploads directory so photos survive a container restart.

**API base path is `/v1`** (set globally in `main.ts`), with global `ValidationPipe({ whitelist: true, transform: true })`. See [docs/api.md](docs/api.md) for the intended public/webhook/admin endpoint contract — several listed endpoints (e.g. checkout, webhooks) are not fully implemented yet.

**`packages/contracts`** holds shared TS types (e.g. `Location`, `OrderStatus`) meant to be consumed by both `apps/api` and `apps/admin`; keep API DTOs and admin types in sync with it rather than redefining shapes locally.

**`apps/admin`** is a real Vite + React app (`src/App.tsx` + `src/components/*Panel.tsx`) with password login (`AdminAuthGuard`, HMAC-signed bearer token) and real API calls against `apps/api/src/modules/admin/*`: an Orders tab (accept/prepare/ready, 5s auto-refresh), catalog CRUD (categories/items/modifiers), promotions, and catalog import/export.

## Domain flow (direct orders)

Customer selects location → server-priced cart snapshot → order created `PENDING_PAYMENT` with idempotency key → payment adapter creates checkout → verified webhook moves order to `PAID` (real for ЮKassa — see `PaymentWebhookController`; the client also polls `GET /v1/orders/:id` while the payment screen is open, since it never trusts the webhook's own redirect) → restaurant accepts → delivery adapter creates delivery → provider events update status → outbox/reconciliation retries unfinished external calls. Full detail in [docs/architecture.md](docs/architecture.md) (Russian) and [docs/wiki/](docs/wiki/en/README.md) (bilingual reference, updated as work lands).

## Linear sync

FR/NFR backlog is tracked in Linear, workspace `silkway`, team `Silkway` (key `SIL`), split across two projects: `SilkWayPlatform` (backend/platform) and `SilkWayIOS` (Flutter mobile, both iOS and Android). Whenever doing coding work against one of these tracked epics:

- Before starting, find the matching Linear issue (`list_issues` / search by title) rather than re-deriving scope from scratch.
- When you start substantive work on an issue still in `Backlog`, move it to `In Progress`.
- When a meaningful chunk of work lands (e.g. a PR is pushed), add a comment on the issue summarizing what shipped and what's still open against that issue's scope, linking the PR.
- Only move an issue to `Done` when its full scope is actually complete — these epics are broad (e.g. "search/filter" bundled with basic browsing), so a partial UI/asset change is progress, not completion. Default to `In Progress` + a comment rather than closing early.
- Never merge a PR without explicit user approval, regardless of Linear status.

**PR titles** follow `[SIL-XX] type: short description` — `SIL-XX` is the Linear issue the PR's work is scoped to (the one being moved to `In Progress`/commented on above), `type` is a conventional-commit-style prefix (`feat`, `fix`, `chore`, `refactor`, ...), and the description is a short imperative summary. When a PR spans multiple epics (e.g. a foundational scaffold), list every issue it actually touches as a comma-separated bracket: `[SIL-1, SIL-2, ...] type: short description` — only include issues with real corresponding work, not every issue that exists.

## Daily workflow

At the start of the first session on a given calendar day, before diving into new work:

- Recap where things stand: what shipped since the last recap (real, tested, committed — not "written but unverified"), and what's still open against the epics currently in flight. Ground this in `git log`, current Linear issue states, and open PRs — don't reconstruct it purely from memory of a prior conversation, since memory can go stale.
- Check whether anything committed since the last recap still needs a Linear comment (see Linear sync below) or still needs pushing/a PR — this is the most common thing to drift out of sync when a session ends mid-task.
- Note it explicitly if a PR has been open for a while without merging — don't merge it yourself, just surface it so the user can decide.

This is a recap for orientation, not a blocking checklist — if the user asks for something specific, do that; give the recap alongside it or when a new day's work is starting cold.

## Wiki

[docs/wiki/](docs/wiki/en/README.md) is a bilingual (EN + RU, mirrored folders `docs/wiki/en/` and `docs/wiki/ru/`) reference layer above the code — architecture at a glance, integrations status, local dev/testing setup. It's meant to stay current: when a piece of work changes something a wiki page describes (an integration goes from stub to real, a new gotcha is discovered, a convention changes), update the relevant page in **both** languages as part of that work, not as a separate cleanup pass later. `docs/architecture.md`, `docs/api.md`, and the ADRs remain the detailed/authoritative sources for their specific topics — the wiki links out to them rather than duplicating.

## Non-obvious conventions

- Money is stored/queried as integer minor units (`price_minor`, kopecks) in Postgres but exposed as `priceRub` (float rubles) in API/service types — conversion happens in the service layer (see `CatalogService.getForLocation`).
- Row types from `pg` queries use `snake_case` (matching SQL columns); mapped API-facing types use `camelCase`. Keep that boundary at the service layer, not in controllers.
- This is pre-production scaffolding, not legal advice — see the "Important" section in [README.md](README.md) and [docs/security-and-compliance-ru.md](docs/security-and-compliance-ru.md) before treating any payment/fiscalization/consent behavior as production-ready.
