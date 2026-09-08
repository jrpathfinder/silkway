import '../../../core/models/order.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/courier_repository.dart';

/// Курьерские заказы через бэкенд (CourierOrdersController, без авторизации —
/// у курьера пока нет ни логина, ни отдельной сессии, см. ADR-003).
class CourierRepositoryHttp implements CourierRepository {
  CourierRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<List<Order>> listOfferedOrders() async {
    final res = await _client.dio.get('/v1/courier/orders/offered');
    return (res.data['data'] as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    await _client.dio.post('/v1/courier/orders/$orderId/accept');
  }

  @override
  Future<void> denyOrder(String orderId) async {
    await _client.dio.post('/v1/courier/orders/$orderId/deny');
  }

  @override
  Future<void> markDelivered(String orderId) async {
    await _client.dio.post('/v1/courier/orders/$orderId/deliver');
  }
}
