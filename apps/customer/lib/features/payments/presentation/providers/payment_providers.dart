import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ports/payment_repository.dart';
import '../../../../core/providers.dart';
import '../../../orders/data/orders_repository_mock.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../data/payment_repository_http.dart';
import '../../data/payment_repository_mock.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final env = ref.watch(envProvider);
  if (env.useMocks) {
    // Safe cast: ordersRepositoryProvider resolves to OrdersRepositoryMock
    // whenever useMocks is true (see orders_providers.dart) — the mock
    // payment repository needs the concrete type to simulate the webhook
    // that would otherwise mark the order PAID.
    final ordersRepo = ref.watch(ordersRepositoryProvider) as OrdersRepositoryMock;
    return PaymentRepositoryMock(ordersRepo);
  }
  return PaymentRepositoryHttp(ref.watch(apiClientProvider));
});
