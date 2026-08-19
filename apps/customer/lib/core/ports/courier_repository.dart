import '../models/order.dart';

/// No backend courier-assignment surface exists yet — mock-only until that
/// lands (see the "Delivery" epic's own-courier assignment engine).
abstract class CourierRepository {
  Future<List<Order>> listOfferedOrders();
  Future<void> acceptOrder(String orderId);
  Future<void> denyOrder(String orderId);
}
