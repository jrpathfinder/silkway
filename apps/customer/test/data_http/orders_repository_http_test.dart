import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/order.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/core/ports/orders_repository.dart';
import 'package:silkway_app/features/orders/data/orders_repository_http.dart';

import '../helpers/fakes.dart';

const _order = '''
{
  "id": "order-1",
  "locationId": "ca-moscow-1",
  "customerId": "+79990000000",
  "lines": [{"itemId": "plov-classic", "name": "Плов классический", "quantity": 1, "unitPriceRub": 590}],
  "totalRub": 590,
  "status": "PENDING_PAYMENT",
  "createdAt": "2026-08-19T12:00:00.000Z"
}
''';

const _orderJson = '{"data": $_order}';

void main() {
  test('create POSTs the order payload with the idempotency header', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/orders');
      expect(options.headers['Idempotency-Key'], 'key-1');
      return (200, _orderJson);
    });

    final repo = OrdersRepositoryHttp(client);
    final order = await repo.create(
      locationId: 'ca-moscow-1',
      customerId: '+79990000000',
      lines: const [CreateOrderLineInput(itemId: 'plov-classic', quantity: 1, modifierIds: [])],
      idempotencyKey: 'key-1',
      fulfillmentType: FulfillmentType.delivery,
    );

    expect(order.id, 'order-1');
  });

  test('getById GETs the order by id', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/orders/order-1');
      return (200, _orderJson);
    });

    final repo = OrdersRepositoryHttp(client);
    final order = await repo.getById('order-1');

    expect(order.id, 'order-1');
  });

  test('listForCustomer GETs /v1/orders with customerId as a query parameter', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    final adapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/orders');
      expect(options.queryParameters['customerId'], '+79990000000');
      return (200, '{"data": [$_order]}');
    });
    client.dio.httpClientAdapter = adapter;

    final repo = OrdersRepositoryHttp(client);
    final orders = await repo.listForCustomer('+79990000000');

    expect(orders, hasLength(1));
    expect(orders.single.id, 'order-1');
  });
}
