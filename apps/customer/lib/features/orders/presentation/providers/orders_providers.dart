import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/order.dart';
import '../../../../core/ports/orders_repository.dart';
import '../../../../core/providers.dart';
import '../../data/orders_repository_http.dart';
import '../../data/orders_repository_mock.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? OrdersRepositoryMock() : OrdersRepositoryHttp(ref.watch(apiClientProvider));
});

final orderByIdProvider = FutureProvider.family<Order, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).getById(orderId);
});

final ordersForCustomerProvider = FutureProvider.family<List<Order>, String>((ref, customerId) {
  return ref.watch(ordersRepositoryProvider).listForCustomer(customerId);
});
