import '../models/payment.dart';

/// Контракт создания платёжной сессии.
abstract class PaymentRepository {
  Future<PaymentCheckout> createCheckout(String orderId);
}
