import 'package:dio/dio.dart';

import '../../../core/models/delivery.dart';
import '../../../core/models/order.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/orders_repository.dart';

/// Заказы через бэкенд.
class OrdersRepositoryHttp implements OrdersRepository {
  OrdersRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
    required FulfillmentType fulfillmentType,
    DeliveryAddress? deliveryAddress,
  }) async {
    final res = await _client.dio.post(
      '/v1/orders',
      data: {
        'locationId': locationId,
        'customerId': customerId,
        'lines': [
          for (final line in lines) {'itemId': line.itemId, 'quantity': line.quantity, 'modifierIds': line.modifierIds},
        ],
        'fulfillmentType': fulfillmentType.toWire(),
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress.toJson(),
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
    final res = await _client.dio.get('/v1/orders', queryParameters: {'customerId': customerId});
    return (res.data['data'] as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }
}
