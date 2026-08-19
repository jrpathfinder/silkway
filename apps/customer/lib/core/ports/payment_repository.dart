import '../models/payment.dart';

abstract class PaymentRepository {
  Future<PaymentCheckout> createCheckout(String orderId);
}
