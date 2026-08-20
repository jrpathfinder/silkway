import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/payments/data/payment_repository_http.dart';

import '../helpers/fakes.dart';

void main() {
  test('createCheckout POSTs to the order checkout endpoint and unwraps `data`', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/orders/order-1/checkout');
      return (200, '{"data": {"id": "pay-1", "status": "pending", "confirmationUrl": "https://pay.example/1"}}');
    });

    final repo = PaymentRepositoryHttp(client);
    final checkout = await repo.createCheckout('order-1');

    expect(checkout.id, 'pay-1');
    expect(checkout.confirmationUrl, 'https://pay.example/1');
  });
}
