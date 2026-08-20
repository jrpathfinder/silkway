import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/auth/application/session_notifier.dart';

import '../helpers/fakes.dart';

void main() {
  test('build starts unauthenticated when no session is stored', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);

    final session = await container.read(sessionNotifierProvider.future);
    expect(session.isAuthenticated, isFalse);
    expect(session.customerId, isNull);
  });

  test('build restores a previously saved session', () async {
    final storage = FakeSecureStorage();
    await storage.saveSession(accessToken: 'token', refreshToken: 'refresh', phone: '+79990000000');
    final container = ProviderContainer(overrides: testOverrides(secureStorage: storage));
    addTearDown(container.dispose);

    final session = await container.read(sessionNotifierProvider.future);
    expect(session.isAuthenticated, isTrue);
    expect(session.customerId, '+79990000000');
  });

  test('requestOtp delegates to the auth repository', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    await container.read(sessionNotifierProvider.future);

    final result = await container.read(sessionNotifierProvider.notifier).requestOtp('+79990000000');
    expect(result.accepted, isTrue);
  });

  test('verifyOtp with the mock dev code authenticates and persists the session', () async {
    final storage = FakeSecureStorage();
    final container = ProviderContainer(overrides: testOverrides(secureStorage: storage));
    addTearDown(container.dispose);
    await container.read(sessionNotifierProvider.future);

    final verified = await container.read(sessionNotifierProvider.notifier).verifyOtp('+79990000000', '0000');

    expect(verified, isTrue);
    expect(container.read(sessionNotifierProvider).value?.isAuthenticated, isTrue);
    expect(await storage.hasSession(), isTrue);
  });

  test('verifyOtp with a wrong code stays unauthenticated', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    await container.read(sessionNotifierProvider.future);

    final verified = await container.read(sessionNotifierProvider.notifier).verifyOtp('+79990000000', '1234');

    expect(verified, isFalse);
    expect(container.read(sessionNotifierProvider).value?.isAuthenticated, isFalse);
  });

  test('logout clears the stored session', () async {
    final storage = FakeSecureStorage();
    final container = ProviderContainer(overrides: testOverrides(secureStorage: storage));
    addTearDown(container.dispose);
    await container.read(sessionNotifierProvider.future);
    await container.read(sessionNotifierProvider.notifier).verifyOtp('+79990000000', '0000');

    await container.read(sessionNotifierProvider.notifier).logout();

    expect(container.read(sessionNotifierProvider).value?.isAuthenticated, isFalse);
    expect(await storage.hasSession(), isFalse);
  });
}
