# Архитектура платформы

## Цель

Запустить прямой канал заказов для одной московской точки ресторана, не связывая доменную модель с конкретным платежным, курьерским или маркетплейс-провайдером. Модель `Brand -> City -> Location` используется с первого дня, поэтому добавление новых точек в Москве не потребует изменения схемы.

## Контейнеры

```text
Flutter customer app ─┐
                      ├── API / modular monolith ── PostgreSQL
Web admin ────────────┘          │                 ├── Redis
                                 │                 └── Object storage
                                 ├── PaymentProvider (ЮKassa)
                                 ├── DeliveryProvider (Yandex Delivery)
                                 ├── Marketplace adapters (Yandex Eda)
                                 └── SMS / push / maps providers
```

Модульный монолит выбран для MVP: границы модулей и события определены заранее, но эксплуатационная сложность микросервисов не вводится до появления нагрузки и отдельных команд.

## Основные модули

- Identity: телефонный OTP, сессии, consent records.
- Locations: города, точки, часы работы, зоны доставки.
- Catalog: категории, блюда, модификаторы, цены и остатки.
- Cart/Orders: snapshot корзины, идемпотентность, state machine.
- Payments: создание платежа, webhook, возврат, чек.
- Delivery: расчет, создание доставки, tracking, cancel.
- Integrations: Yandex Eda, Yandex Delivery и будущие POS-провайдеры.
- Admin/Audit: RBAC и неизменяемый журнал действий.

## Поток прямого заказа

1. Клиент выбирает точку и получает меню.
2. Backend пересчитывает корзину на сервере и сохраняет snapshot цены.
3. Заказ создается в статусе `PENDING_PAYMENT` с idempotency key.
4. Payment adapter создает checkout и возвращает redirect URL.
5. Verified payment webhook переводит заказ в `PAID`.
6. Ресторан принимает заказ; delivery adapter создает доставку.
7. Provider events обновляют статус заказа, клиент получает push/SMS.
8. Outbox и reconciliation job повторяют незавершенные внешние операции.

## Масштабирование

На первом этапе один API и одна PostgreSQL. Кэшировать только read-модель каталога; цены, наличие, оплату и переходы статусов всегда проверять транзакционно. При росте нагрузки первыми можно выделить notifications, integrations и catalog read API, не меняя публичные контракты.
