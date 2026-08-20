import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/courier/data/courier_repository_http.dart';
import 'package:silkway_app/features/loyalty/data/loyalty_repository_http.dart';

import '../helpers/fakes.dart';

/// Both of these are stubs — no backend surface exists yet for courier
/// assignment or loyalty (see ADR-003) — so all they should do is throw
/// [UnimplementedError] rather than silently return bogus data.
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

  group('CourierRepositoryHttp', () {
    test('listOfferedOrders throws UnimplementedError', () {
      final repo = CourierRepositoryHttp(client);
      expect(() => repo.listOfferedOrders(), throwsUnimplementedError);
    });

    test('acceptOrder throws UnimplementedError', () {
      final repo = CourierRepositoryHttp(client);
      expect(() => repo.acceptOrder('order-1'), throwsUnimplementedError);
    });

    test('denyOrder throws UnimplementedError', () {
      final repo = CourierRepositoryHttp(client);
      expect(() => repo.denyOrder('order-1'), throwsUnimplementedError);
    });
  });
}
