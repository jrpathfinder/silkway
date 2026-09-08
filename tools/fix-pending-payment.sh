#!/usr/bin/env bash
# Manual stand-in for a real ЮKassa webhook, which can't reach a local/dev
# backend (see docs/wiki/*/integrations.md). Run this whenever the app is
# stuck showing "Спасибо!" after a real payment — it checks with ЮKassa
# directly whether the payment actually succeeded, and if so, replays the
# exact webhook call our own PaymentWebhookController would have received,
# so it goes through the same re-verification path a real webhook would.
#
# Usage:
#   tools/fix-pending-payment.sh              # auto-picks the most recent PENDING_PAYMENT order
#   tools/fix-pending-payment.sh <order-id>   # target a specific order
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

API_BASE="${API_BASE_URL:-http://localhost:3000}"
ENV_FILE="apps/api/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE — copy it from .env.example first." >&2
  exit 1
fi

SHOP_ID=$(grep '^YOOKASSA_SHOP_ID=' "$ENV_FILE" | cut -d= -f2)
SECRET=$(grep '^YOOKASSA_SECRET_KEY=' "$ENV_FILE" | cut -d= -f2)
ADMIN_PASSWORD=$(grep '^ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2)

ORDER_ID="${1:-}"

if [ -z "$ORDER_ID" ]; then
  echo "No order id given — looking up the most recent PENDING_PAYMENT order..."
  TOKEN=$(curl -s -X POST "$API_BASE/v1/admin/auth/login" -H "Content-Type: application/json" \
    -d "{\"password\":\"$ADMIN_PASSWORD\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['token'])")
  ORDER_ID=$(curl -s "$API_BASE/v1/admin/orders?status=PENDING_PAYMENT" -H "Authorization: Bearer $TOKEN" | python3 -c "
import json, sys
orders = [o for o in json.load(sys.stdin)['data'] if o.get('paymentId')]
orders.sort(key=lambda o: o['createdAt'], reverse=True)
print(orders[0]['id'] if orders else '')
")
  if [ -z "$ORDER_ID" ]; then
    echo "No pending-payment orders with a checkout started. Nothing to fix."
    exit 0
  fi
fi
echo "Order: $ORDER_ID"

PAYMENT_ID=$(curl -s "$API_BASE/v1/orders/$ORDER_ID" | python3 -c "import json,sys; print(json.load(sys.stdin)['data'].get('paymentId',''))")
if [ -z "$PAYMENT_ID" ]; then
  echo "That order has no paymentId yet — checkout was never created for it." >&2
  exit 1
fi

echo "Checking ЮKassa payment $PAYMENT_ID..."
read -r PSTATUS PPAID < <(curl -s -u "$SHOP_ID:$SECRET" "https://api.yookassa.ru/v3/payments/$PAYMENT_ID" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status'), d.get('paid'))")

if [ "$PSTATUS" != "succeeded" ] || [ "$PPAID" != "True" ]; then
  echo "Not actually paid yet on ЮKassa's side (status=$PSTATUS paid=$PPAID) — nothing to fix. Wait for the customer to finish the payment form."
  exit 1
fi

echo "Confirmed succeeded on ЮKassa's side — replaying the webhook..."
curl -s -X POST "$API_BASE/v1/webhooks/payments/yookassa" \
  -H "Content-Type: application/json" \
  -d "{\"event\":\"payment.succeeded\",\"object\":{\"id\":\"$PAYMENT_ID\"}}" > /dev/null

sleep 1
NEW_STATUS=$(curl -s "$API_BASE/v1/orders/$ORDER_ID" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['status'])")
echo "Order $ORDER_ID is now: $NEW_STATUS"
