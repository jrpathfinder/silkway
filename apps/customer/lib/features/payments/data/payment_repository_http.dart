import '../../../core/models/payment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/payment_repository.dart';

class PaymentRepositoryHttp implements PaymentRepository {
  PaymentRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<PaymentCheckout> createCheckout(String orderId) async {
    final res = await _client.dio.post('/v1/orders/$orderId/checkout');
    return PaymentCheckout.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
