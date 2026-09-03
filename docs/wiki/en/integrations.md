# Integrations status

RU: [`../ru/integrations.md`](../ru/integrations.md). Update both when this changes.

All four ports live in `apps/api/src/modules/integrations/ports/*.port.ts`. Concrete providers are bound in `integrations.module.ts`, switched by env var, always defaulting to mock.

## SMS (OTP delivery) — real, code-complete

- **Port**: `SmsProvider` (`sms.port.ts`)
- **Providers**: `MockSmsProvider` (logs the code instead of sending it) / `SmsRuProvider` (real [sms.ru](https://sms.ru) integration)
- **Switch**: `SMS_PROVIDER=mock|sms.ru`, real mode needs `SMS_RU_API_ID`
- **Status**: code works and was verified against the real sms.ru API. Currently blocked *externally*, not in code — sms.ru rejects delivery until the account registers a sender name (буквенное имя отправителя) at sms.ru's sender panel. No code changes needed once that's approved — just flip `SMS_PROVIDER` back to `sms.ru`.
- **Dev convenience**: when on the mock provider, `AuthService.requestOtp`'s response includes a `devCode` field with the real code — the Flutter app shows it inline on the OTP screen, no server-log reading required. This field is never present when the real provider is active.

## Payment — real, code-complete

- **Port**: `PaymentProvider` (`payment.port.ts`)
- **Providers**: `MockPaymentProvider` / `YookassaPaymentProvider` (real ЮKassa REST API v3)
- **Switch**: `PAYMENT_PROVIDER=mock|yookassa`, real mode needs `YOOKASSA_SHOP_ID` + `YOOKASSA_SECRET_KEY`
- **Status**: verified end-to-end against ЮKassa's real test-mode API — created a real payment session, completed it with ЮKassa's own test card through the app's actual WebView, confirmed the webhook fired and updated order status correctly.
- **Webhook**: lives in `apps/api/src/modules/orders/payment-webhook.controller.ts`, *not* in `integrations/` — it needs `OrdersService` to update order status, and `OrdersModule` already imports `IntegrationsModule` (not the reverse, to avoid a circular import). ЮKassa doesn't sign webhook payloads, so the handler never trusts the POST body directly — on any notification it re-fetches the payment from ЮKassa's API with its own credentials and only acts on that authoritative response.
- **Mock mode dev flow**: `MockPaymentProvider.createPayment` points the WebView at `GET /v1/mock-checkout`, a real page with a "Pay" button that calls `POST /v1/orders/:id/mark-paid-demo` — no manual curl needed to complete a test purchase locally.
- **Getting ЮKassa test credentials**: registering a real business isn't required for test-mode keys. In the ЮKassa dashboard, a **test shop** is created automatically during onboarding and its own shopId + secret key (under Настройки → Ключи API / Интеграция → Ключи API for that specific test shop, *not* the payouts gateway — that's a different product with a different key) work immediately, independent of whether the live-business questionnaire is finished.
- **Not done**: refund flow is implemented in the provider but untested end-to-end; no admin-panel UI to trigger one yet.

## Delivery — not started

- **Port**: `DeliveryProvider` (`delivery.port.ts`) — `quote` / `create` / `cancel`
- **Providers**: none. Not even a mock exists, and the port isn't bound in `integrations.module.ts` at all.
- **Env vars present but unused**: `DELIVERY_PROVIDER`, `YANDEX_DELIVERY_ENABLED`

## Marketplace (Yandex Eda live sync) — not started

- **Port**: `MarketplaceMenuAdapter` (`marketplace.port.ts`) — `publishMenu` / `pullOrders` / `acknowledgeOrder`
- **Providers**: none, same as delivery.
- **Don't confuse this with the menu importer**: `tools/import-yandex-menu.mjs` (pulls the raw Yandex Eda menu JSON, one-time) and `tools/map-yandex-menu.mjs` (maps it into the admin catalog import format) are real, working, and were used to seed the actual restaurant's live menu into the catalog — but they're a one-off migration script, not this port's live bidirectional sync. Building this port for real is separate, larger work.
- **Env var present but unused**: `YANDEX_EDA_ENABLED`
