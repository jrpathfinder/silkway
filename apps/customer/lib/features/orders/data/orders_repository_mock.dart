import 'dart:convert';
import 'dart:math';

import '../../../core/models/delivery.dart';
import '../../../core/models/order.dart';
import '../../../core/ports/catalog_repository.dart';
import '../../../core/ports/orders_repository.dart';
import '../../../core/storage/local_kv.dart';

const _storageKey = 'silkway.orders.v1';

/// Мок заказов: хранит их в памяти и повторяет ключевые правила бэкенда —
/// пересчёт цен по каталогу на своей стороне и идемпотентность создания.
///
/// Заказы также сохраняются в LocalKv (SharedPreferences), поэтому история
/// заказов и статус переживают перезапуск приложения — до этого при
/// перезапуске всё терялось, потому что это была чистая in-memory Map.
/// Ключ идемпотентности не сохраняется — это в любом случае только защита
/// от дублей внутри одной сессии, не то, что нужно переживать перезапуск.
class OrdersRepositoryMock implements OrdersRepository {
  OrdersRepositoryMock(this._catalog, this._localKv);

  final CatalogRepository _catalog;
  final LocalKv _localKv;
  final Map<String, Order> _orders = {};
  final Map<String, String> _idempotency = {};
  Future<void>? _restoreFuture;

  Future<void> _ensureRestored() => _restoreFuture ??= _restore();

  Future<void> _restore() async {
    final raw = await _localKv.getString(_storageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final order = Order.fromJson(item as Map<String, dynamic>);
        _orders[order.id] = order;
      }
    } catch (_) {
      // Повреждённые локальные данные — просто начинаем с чистого листа
      // вместо падения при старте.
    }
  }

  Future<void> _persist() async {
    final list = _orders.values.map((o) => o.toJson()).toList();
    await _localKv.setString(_storageKey, jsonEncode(list));
  }

  @override
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
    required FulfillmentType fulfillmentType,
    DeliveryAddress? deliveryAddress,
  }) async {
    await _ensureRestored();
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
    await _persist();
    return order;
  }

  @override
  Future<Order> getById(String orderId) async {
    await _ensureRestored();
    await Future.delayed(const Duration(milliseconds: 150));
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found: $orderId');
    return order;
  }

  @override
  Future<List<Order>> listForCustomer(String customerId) async {
    await _ensureRestored();
    await Future.delayed(const Duration(milliseconds: 150));
    final orders = _orders.values.where((o) => o.customerId == customerId).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Mock-only: not part of [OrdersRepository] since real payment status
  /// transitions happen via a verified webhook server-side (docs/api.md
  /// "Webhooks"), never a direct client call. Used by PaymentRepositoryMock
  /// to simulate that webhook completing.
  Future<void> markPaidForDemo(String orderId) async {
    await _ensureRestored();
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
    await _persist();
  }
}
