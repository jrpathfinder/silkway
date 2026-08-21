import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/payment.dart';

void main() {
  test('PaymentCheckout.fromJson parses status by name', () {
    final checkout = PaymentCheckout.fromJson({
      'id': 'mock_payment_1',
      'status': 'succeeded',
      'confirmationUrl': 'https://mock.silkway.local/checkout?orderId=1',
    });
    expect(checkout.id, 'mock_payment_1');
    expect(checkout.status, PaymentStatus.succeeded);
    expect(checkout.confirmationUrl, 'https://mock.silkway.local/checkout?orderId=1');
  });
}
