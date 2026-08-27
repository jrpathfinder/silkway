import '../models/order.dart';

/// No per-courier assignment or courier auth exists yet — accept/deny act
/// against a shared pool of READY_FOR_DELIVERY orders, first accept wins.
abstract class CourierRepository {
  Future<List<Order>> listOfferedOrders();
  Future<void> acceptOrder(String orderId);
  Future<void> denyOrder(String orderId);
  Future<void> markDelivered(String orderId);
}
