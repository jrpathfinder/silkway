import '../../../core/models/payment.dart';
import '../../../core/ports/payment_repository.dart';
import '../../orders/data/orders_repository_mock.dart';

/// Мок оплаты: платёж «проходит» сразу и переводит заказ в PAID, изображая
/// то, что в реальности делает вебхук платёжного провайдера.
class PaymentRepositoryMock implements PaymentRepository {
  PaymentRepositoryMock(this._ordersMock);

  final OrdersRepositoryMock _ordersMock;

  @override
  Future<PaymentCheckout> createCheckout(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No real backend to host a hosted-checkout page in mock mode, so
    // payment "succeeds" immediately and the linked mock order is marked
    // PAID directly, simulating what the real verified webhook does
    // server-side (see docs/api.md "Webhooks").
    await _ordersMock.markPaidForDemo(orderId);
    return PaymentCheckout(
      id: 'mock_payment_$orderId',
      status: PaymentStatus.succeeded,
      confirmationUrl: 'https://mock.silkway.local/checkout?orderId=$orderId',
    );
  }
}
