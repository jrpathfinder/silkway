import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/order.dart';
import 'package:silkway_app/core/ports/orders_repository.dart';
import 'package:silkway_app/features/catalog/data/catalog_repository_mock.dart';
import 'package:silkway_app/features/orders/data/orders_repository_mock.dart';

import '../helpers/fakes.dart';

void main() {
  test('an order survives being recreated with the same LocalKv (simulates an app restart)', () async {
    final localKv = FakeLocalKv();
    final first = OrdersRepositoryMock(CatalogRepositoryMock(), localKv);

    final order = await first.create(
      locationId: 'ca-moscow-1',
      customerId: '+79990000000',
      lines: const [CreateOrderLineInput(itemId: 'samsa-lamb', quantity: 2)],
      idempotencyKey: 'key-1',
      fulfillmentType: FulfillmentType.pickup,
    );

    // Свежий инстанс — как будто приложение перезапустили; данные должны
    // прийти из LocalKv, а не быть потеряны вместе со старой in-memory Map.
    final second = OrdersRepositoryMock(CatalogRepositoryMock(), localKv);
    final restored = await second.getById(order.id);

    expect(restored.id, order.id);
    expect(restored.customerId, '+79990000000');
    expect(restored.lines.single.itemId, 'samsa-lamb');
    expect(restored.fulfillmentType, FulfillmentType.pickup);

    final forCustomer = await second.listForCustomer('+79990000000');
    expect(forCustomer.map((o) => o.id), contains(order.id));
  });

  test('markPaidForDemo persists the status change across a restart', () async {
    final localKv = FakeLocalKv();
    final first = OrdersRepositoryMock(CatalogRepositoryMock(), localKv);
    final order = await first.create(
      locationId: 'ca-moscow-1',
      customerId: '+79990000001',
      lines: const [CreateOrderLineInput(itemId: 'samsa-lamb', quantity: 1)],
      idempotencyKey: 'key-2',
      fulfillmentType: FulfillmentType.pickup,
    );
    await first.markPaidForDemo(order.id);

    final second = OrdersRepositoryMock(CatalogRepositoryMock(), localKv);
    final restored = await second.getById(order.id);
    expect(restored.status, OrderStatus.paid);
  });
}
