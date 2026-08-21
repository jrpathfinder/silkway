import '../../../core/models/order.dart';
import '../../../core/ports/courier_repository.dart';

/// Мок курьерских заказов: пустой список, приём и отказ ничего не делают.
class CourierRepositoryMock implements CourierRepository {
  @override
  Future<List<Order>> listOfferedOrders() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [];
  }

  @override
  Future<void> acceptOrder(String orderId) async {}

  @override
  Future<void> denyOrder(String orderId) async {}
}
