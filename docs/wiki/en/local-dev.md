# Local development & testing

RU: [`../ru/local-dev.md`](../ru/local-dev.md). Update both when this changes.

## Running the stack

```bash
npm install
cp apps/api/.env.example apps/api/.env
docker compose -f infra/docker-compose.yml up -d      # Postgres + Redis
npm --workspace apps/api run start:dev                 # API, port 3000
cd apps/admin && npm run dev                            # admin panel, port 5173
```

**macOS sleep kills both Docker and any background dev servers.** If the Mac has slept, expect to need: `open -a Docker` (wait for the daemon), `docker compose ... up -d` again, and a fresh `start:dev`/`npm run dev` for anything that was running in the background. Check for this first whenever something that worked a moment ago suddenly can't connect.

## Testing the Flutter apps

Two flavors, one codebase: `lib/main_customer.dart` / `lib/main_courier.dart`. Build with `--dart-define=USE_MOCKS=false` to hit the real backend, `API_BASE_URL` pointed at wherever the backend is actually reachable from (see below).

### iOS Simulator

Simulators reach the Mac's own `localhost` directly — simplest path, no network configuration needed. Two simulators booted simultaneously get their own windows and can run customer + courier side by side without any bundle-ID trick, since they're separate devices.

**Tap coordinates are in device points, not screenshot pixels.** For an iPhone 16 Pro that's 402×874 — reason in that coordinate space directly (e.g. "this button is about 90% down the screen" → y≈786), don't estimate from the screenshot image's own pixel dimensions and pass those numbers through unconverted. A coordinate outside 0–402 / 0–874 silently taps nothing.

### Physical device

The device can't reach the Mac's `localhost` — `API_BASE_URL` needs the Mac's actual LAN address, and both need to be reachable from each other. Three real gotchas, each cost real debugging time:

1. **Public/venue Wi-Fi often blocks device-to-device traffic** (client isolation) — a phone and Mac can both be on "the same" hotel/cafe Wi-Fi and still be unable to reach each other at all, with requests hanging until timeout rather than failing fast. If a physical-device build that worked before suddenly can't reach the backend, check what network the Mac is actually on before debugging code. The reliable fix: use the phone's own Personal Hotspot and have the Mac join *that* — a hotspot has no isolation between its own two devices.
2. **iOS blocks plain HTTP by default (App Transport Security)** — the Simulator quietly exempts `localhost` from this, which is exactly why a physical-device build can fail here even when the identical Simulator build works. Needs `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` in `ios/Runner/Info.plist` for a plain-HTTP dev backend. (Not needed once there's a real HTTPS deployment.)
3. **iOS 14+ Local Network Privacy** blocks connections to any private IP (192.168.x, 172.16–31.x — including a Personal Hotspot's 172.20.10.x range) unless `NSLocalNetworkUsageDescription` is declared in `Info.plist`. Again, the Simulator doesn't enforce this at all, so it never shows up there.

Both apps share one `ios/Runner/Info.plist` and one Xcode project — the `NSAppTransportSecurity` fix should be a **permanent** change (it's in the repo). A courier-flavor build needing its own bundle ID (to install alongside the customer flavor on one physical device) is currently done via a **temporary** `sed` override of `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj` for that one build, reverted immediately after — not committed. If courier needs to coexist with customer on a device regularly, that's worth turning into a real Xcode flavor/scheme setup instead of repeating the override dance each time.

## Backend state resets on restart

`OrdersService` is in-memory — every restart (including the ones from a Mac waking up and needing services relaunched) wipes all orders. Don't be surprised when an order that was `DELIVERED` five minutes ago is just gone.
