import 'dart:math';

import '../../../core/models/delivery.dart';
import '../../../core/models/order.dart';
import '../../../core/ports/catalog_repository.dart';
import '../../../core/ports/orders_repository.dart';

/// Мок заказов: хранит их в памяти и повторяет ключевые правила бэкенда —
/// пересчёт цен по каталогу на своей стороне и идемпотентность создания.
///
/// Цены и названия берутся из [CatalogRepository] на каждый create(), а не из
/// отдельного захардкоженного списка — раньше здесь была своя копия каталога,
/// и она дважды тихо разошлась с настоящим при правках меню (блюдо не
/// находилось вовсе, либо цена оставалась старой).
class OrdersRepositoryMock implements OrdersRepository {
  OrdersRepositoryMock(this._catalog);

  final CatalogRepository _catalog;
  final Map<String, Order> _orders = {};
  final Map<String, String> _idempotency = {};

  @override
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
    required FulfillmentType fulfillmentType,
    DeliveryAddress? deliveryAddress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existingId = _idempotency[idempotencyKey];
    if (existingId != null) return _orders[existingId]!;

    final catalog = await _catalog.getForLocation(locationId);
    final orderLines = lines.map((line) {
      final item = catalog.itemById(line.itemId);
      final modifiersTotal = item.modifiers
          .where((m) => line.modifierIds.contains(m.id))
          .fold(0.0, (sum, m) => sum + m.priceRub);
      return OrderLine(
        itemId: item.id,
        name: item.name,
        quantity: line.quantity,
        unitPriceRub: item.priceRub + modifiersTotal,
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
      fulfillmentType: fulfillmentType,
      deliveryAddress: deliveryAddress,
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
      fulfillmentType: order.fulfillmentType,
      deliveryAddress: order.deliveryAddress,
    );
  }
}
