import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/loyalty.dart';
import '../../../../core/ports/loyalty_repository.dart';
import '../../../../core/providers.dart';
import '../../data/loyalty_repository_http.dart';
import '../../data/loyalty_repository_mock.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? LoyaltyRepositoryMock() : LoyaltyRepositoryHttp(ref.watch(apiClientProvider));
});

final promotionsProvider = FutureProvider<List<LoyaltyPromotion>>((ref) {
  return ref.watch(loyaltyRepositoryProvider).listPromotions();
});
