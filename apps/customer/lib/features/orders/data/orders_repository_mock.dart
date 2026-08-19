import 'dart:math';

import '../../../core/models/order.dart';
import '../../../core/ports/orders_repository.dart';

class OrdersRepositoryMock implements OrdersRepository {
  final Map<String, Order> _orders = {};
  final Map<String, String> _idempotency = {};

  // Mirrors CatalogRepositoryMock's fixture exactly, since the real backend
  // always re-fetches & re-prices server-side too (OrdersService.create).
  static const _catalogPrices = {
    'plov-classic': (name: 'Плов классический', priceRub: 590.0, modifiers: {'extra-meat': 180.0}),
    'samsa-lamb': (name: 'Самса с бараниной', priceRub: 220.0, modifiers: <String, double>{}),
  };

  @override
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existingId = _idempotency[idempotencyKey];
    if (existingId != null) return _orders[existingId]!;

    final orderLines = lines.map((line) {
      final catalogEntry = _catalogPrices[line.itemId]!;
      final modifiersTotal = line.modifierIds.fold(0.0, (sum, id) => sum + (catalogEntry.modifiers[id] ?? 0));
      return OrderLine(
        itemId: line.itemId,
        name: catalogEntry.name,
        quantity: line.quantity,
        unitPriceRub: catalogEntry.priceRub + modifiersTotal,
        modifierIds: line.modifierIds,
      );
    }).toList();

    final order = Order(
      id: 'mock-${Random().nextInt(1 << 31)}',
      locationId: locationId,
      customerId: customerId,
      lines: orderLines,
      totalRub: orderLines.fold(0.0, (sum, l) => sum + l.unitPriceRub * l.quantity),
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
    );

    _orders[order.id] = order;
    _idempotency[idempotencyKey] = order.id;
    return order;
  }

  @override
  Future<Order> getById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found: $orderId');
    return order;
  }

  @override
  Future<List<Order>> listForCustomer(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _orders.values.where((o) => o.customerId == customerId).toList();
  }

  /// Mock-only: not part of [OrdersRepository] since real payment status
  /// transitions happen via a verified webhook server-side (docs/api.md
  /// "Webhooks"), never a direct client call. Used by PaymentRepositoryMock
  /// to simulate that webhook completing.
  void markPaidForDemo(String orderId) {
    final order = _orders[orderId];
    if (order == null) return;
    _orders[orderId] = Order(
      id: order.id,
      locationId: order.locationId,
      customerId: order.customerId,
      lines: order.lines,
      totalRub: order.totalRub,
      status: OrderStatus.paid,
      createdAt: order.createdAt,
      paymentId: order.paymentId,
    );
  }
}
