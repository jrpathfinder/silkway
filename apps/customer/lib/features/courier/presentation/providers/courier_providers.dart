import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/order.dart';
import '../../../../core/ports/courier_repository.dart';
import '../../../../core/providers.dart';
import '../../data/courier_repository_http.dart';
import '../../data/courier_repository_mock.dart';

/// Переключатель мок/HTTP для курьерских заказов: выбор зависит от Env.useMocks.
final courierRepositoryProvider = Provider<CourierRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? CourierRepositoryMock() : CourierRepositoryHttp(ref.watch(apiClientProvider));
});

final offeredOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(courierRepositoryProvider).listOfferedOrders();
});

/// Заказы, принятые этим курьером в текущей сессии приложения. Назначения
/// курьеров на бэкенде нет — источник истины для "что я везу" здесь, локально
/// на устройстве, и не переживает перезапуск приложения (это осознанный MVP-
/// компромисс, а не пропущенный кейс).
class MyDeliveriesNotifier extends StateNotifier<List<Order>> {
  MyDeliveriesNotifier() : super(const []);

  void add(Order order) => state = [...state, order];
  void remove(String orderId) => state = state.where((o) => o.id != orderId).toList();
}

final myDeliveriesProvider = StateNotifierProvider<MyDeliveriesNotifier, List<Order>>((ref) {
  return MyDeliveriesNotifier();
});
