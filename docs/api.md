# API starter contract

Base path: `/v1`.

## Public

- `GET /health` — liveness/readiness summary.
- `GET /v1/locations` — active restaurant locations.
- `GET /v1/locations/:locationId/catalog` — localized catalog and availability.
- `POST /v1/auth/otp/request` — request OTP, rate limited.
- `POST /v1/auth/otp/verify` — verify OTP and issue session.
- `POST /v1/orders` — create order with `Idempotency-Key`.
- `POST /v1/orders/:orderId/checkout` — create hosted payment checkout.
- `GET /v1/orders/:orderId` — customer order view.

## Webhooks

- `POST /v1/webhooks/payments/:provider` — verified payment events.
- `POST /v1/webhooks/delivery/:provider` — verified delivery events.

## Admin

Admin endpoints are intentionally represented by the same bounded modules and require staff RBAC. The admin UI starter uses mock data until an admin session and menu-management endpoints are enabled.
