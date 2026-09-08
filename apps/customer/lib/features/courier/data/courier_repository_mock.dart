import '../../../core/models/delivery.dart';
import '../../../core/models/order.dart';
import '../../../core/ports/courier_repository.dart';

/// Мок курьерских заказов: небольшой фиксированный пул готовых к выдаче
/// заказов в памяти, чтобы курьерский флейвор был проверяем и без бэкенда.
class CourierRepositoryMock implements CourierRepository {
  final Map<String, Order> _orders = {
    for (final order in _seed()) order.id: order,
  };

  static List<Order> _seed() {
    final now = DateTime.now();
    return [
      Order(
        id: 'mock-courier-1',
        locationId: 'ca-moscow-1',
        customerId: '+79990000001',
        lines: const [
          OrderLine(itemId: 'plov-classic', name: 'Плов классический', quantity: 1, unitPriceRub: 590, modifierIds: []),
        ],
        totalRub: 590,
        status: OrderStatus.readyForDelivery,
        createdAt: now,
        fulfillmentType: FulfillmentType.delivery,
        deliveryAddress: const DeliveryAddress(lat: 55.751244, lng: 37.618423, addressText: 'Красная площадь, Москва'),
      ),
      Order(
        id: 'mock-courier-2',
        locationId: 'ca-moscow-1',
        customerId: '+79990000002',
        lines: const [
          OrderLine(itemId: 'samsa-lamb', name: 'Самса с бараниной', quantity: 2, unitPriceRub: 220, modifierIds: []),
        ],
        totalRub: 440,
        status: OrderStatus.readyForDelivery,
        createdAt: now,
        fulfillmentType: FulfillmentType.delivery,
        deliveryAddress: const DeliveryAddress(lat: 55.7887, lng: 37.6371, addressText: 'ВДНХ, Москва'),
      ),
    ];
  }

  @override
  Future<List<Order>> listOfferedOrders() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _orders.values.where((o) => o.status == OrderStatus.readyForDelivery).toList();
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    final order = _orders[orderId];
    if (order == null) return;
    _orders[orderId] = _withStatus(order, OrderStatus.inDelivery);
  }

  @override
  Future<void> denyOrder(String orderId) async {}

  @override
  Future<void> markDelivered(String orderId) async {
    final order = _orders[orderId];
    if (order == null) return;
    _orders[orderId] = _withStatus(order, OrderStatus.delivered);
  }

  Order _withStatus(Order order, OrderStatus status) => Order(
        id: order.id,
        locationId: order.locationId,
        customerId: order.customerId,
        lines: order.lines,
        totalRub: order.totalRub,
        status: status,
        createdAt: order.createdAt,
        paymentId: order.paymentId,
        fulfillmentType: order.fulfillmentType,
        deliveryAddress: order.deliveryAddress,
      );
}
