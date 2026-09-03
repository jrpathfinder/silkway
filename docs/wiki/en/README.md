# SilkWay Wiki (EN)

Bilingual reference layer above the code. See [`../ru/README.md`](../ru/README.md) for Russian. When you update a fact here, update the RU mirror too — see [CLAUDE.md](../../../CLAUDE.md#wiki) for the convention.

This wiki is a map, not the territory: it links out to the detailed docs (`docs/architecture.md`, `docs/api.md`, `docs/adr/*`) rather than duplicating them. Start here, follow the links for depth.

## Pages

- [Integrations status](./integrations.md) — what's real, what's mock, what's not started at all, for every external provider
- [Local development & testing](./local-dev.md) — running the stack, testing on physical devices/simulators, the gotchas that have actually bitten people

## What this project is

A Central Asia restaurant delivery platform, MVP scope: single Moscow location, real menu (imported from the restaurant's actual Yandex Eda listing). Three apps in one npm workspace:

| App | Stack | State |
|---|---|---|
| `apps/api` | NestJS, modular monolith, Postgres (optional at runtime) | Core order/catalog/auth flow real and tested; several integrations still mock |
| `apps/admin` | Vite + React | Real — password login, orders, catalog CRUD, promotions, import/export |
| `apps/customer` | Flutter, two flavors (`customer` + `courier`) | Real — full order flow, real payment, courier hand-off |

## Architecture at a glance

**Modular monolith** (see [ADR-001](../../adr/001-modular-monolith.md)): one NestJS process, one Postgres database, modules under `apps/api/src/modules/*` (`health`, `locations`, `catalog`, `auth`, `admin`, `orders`, `integrations`) that only talk to each other through exported services/controllers — never reach into another module's internals.

**Ports and adapters** (see [ADR-002](../../adr/002-provider-adapters.md)): every external provider (payment, SMS, delivery, marketplace) sits behind an abstract port in `apps/api/src/modules/integrations/ports/`. Concrete providers are bound via env vars in `integrations.module.ts`, always defaulting to a mock so the app runs with zero external accounts. See [Integrations status](./integrations.md) for exactly what's wired up today.

**Domain flow**: customer picks a location → server-priced cart → order created `PENDING_PAYMENT` → payment adapter creates a hosted checkout → verified webhook (or, for mock, a manual dev endpoint) moves the order to `PAID` → staff accept/prepare/ready it in the admin panel → a courier accepts and delivers it. Every status transition is server-validated against the order's current state — there's no "set to any status" escape hatch.

**What's still fully in-memory**: `OrdersService` is a `Map`, not the Postgres tables `schema.sql` already defines for it. A backend restart loses every order. This is a known, deliberate MVP gap, not an oversight — don't be surprised when test orders vanish after a restart.

## Where things are tracked

- **Linear** — workspace `silkway`, team `Silkway` (`SIL`), projects `SilkWayPlatform` and `SilkWayIOS`. See the Linear sync convention in [CLAUDE.md](../../../CLAUDE.md#linear-sync).
- **GitHub** — `jrpathfinder/silkway`. PR titles follow `[SIL-XX] type: description`.
