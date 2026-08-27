import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/loyalty/data/loyalty_repository_http.dart';

import '../helpers/fakes.dart';

/// No backend surface exists yet for loyalty (see ADR-003) — it should throw
/// [UnimplementedError] rather than silently return bogus data. Courier's
/// HTTP repository has a real backend now (CourierOrdersController) and is
/// covered separately, not here.
void main() {
  late ApiClient client;

  setUp(() => client = ApiClient(testMockEnv, FakeSecureStorage()));

  group('LoyaltyRepositoryHttp', () {
    test('listPromotions throws UnimplementedError', () {
      final repo = LoyaltyRepositoryHttp(client);
      expect(() => repo.listPromotions(), throwsUnimplementedError);
    });

    test('getAccount throws UnimplementedError', () {
      final repo = LoyaltyRepositoryHttp(client);
      expect(() => repo.getAccount('+79990000000'), throwsUnimplementedError);
    });
  });
}
