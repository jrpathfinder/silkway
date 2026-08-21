import 'package:dio/dio.dart';

import '../../../core/models/order.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/orders_repository.dart';

/// Заказы через бэкенд.
///
/// Создание и получение по id работают; список заказов покупателя — нет,
/// роут для него на бэкенде не заведён.
class OrdersRepositoryHttp implements OrdersRepository {
  OrdersRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
  }) async {
    final res = await _client.dio.post(
      '/v1/orders',
      data: {
        'locationId': locationId,
        'customerId': customerId,
        'lines': [
          for (final line in lines) {'itemId': line.itemId, 'quantity': line.quantity, 'modifierIds': line.modifierIds},
        ],
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Order> getById(String orderId) async {
    final res = await _client.dio.get('/v1/orders/$orderId');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<Order>> listForCustomer(String customerId) async {
    // No backend route exists for this yet (OrdersService.listForCustomer is
    // never wired to a controller route in orders.controller.ts) — use mocks
    // for this feature until it lands (see ADR-003).
    throw UnimplementedError('No backend order-history endpoint yet.');
  }
}
