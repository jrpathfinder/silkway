import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/profile/application/profile_notifier.dart';

import '../helpers/fakes.dart';

void main() {
  test('build starts empty when nothing is stored', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);

    final profile = await container.read(profileNotifierProvider.future);
    expect(profile.isEmpty, isTrue);
  });

  test('save persists name and email, and updates state immediately', () async {
    final localKv = FakeLocalKv();
    final container = ProviderContainer(overrides: testOverrides(localKv: localKv));
    addTearDown(container.dispose);
    await container.read(profileNotifierProvider.future);

    await container.read(profileNotifierProvider.notifier).save(name: 'Иван', email: 'ivan@example.com');

    final state = container.read(profileNotifierProvider).value;
    expect(state?.name, 'Иван');
    expect(state?.email, 'ivan@example.com');
  });

  test('a saved profile is restored by a fresh build', () async {
    final localKv = FakeLocalKv();
    final first = ProviderContainer(overrides: testOverrides(localKv: localKv));
    await first.read(profileNotifierProvider.future);
    await first.read(profileNotifierProvider.notifier).save(name: 'Иван', email: 'ivan@example.com');
    first.dispose();

    final second = ProviderContainer(overrides: testOverrides(localKv: localKv));
    addTearDown(second.dispose);
    final profile = await second.read(profileNotifierProvider.future);

    expect(profile.name, 'Иван');
    expect(profile.email, 'ivan@example.com');
  });

  test('blank fields trim to empty and count as isEmpty', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    await container.read(profileNotifierProvider.future);

    await container.read(profileNotifierProvider.notifier).save(name: '   ', email: '');

    final state = container.read(profileNotifierProvider).value;
    expect(state?.isEmpty, isTrue);
  });
}
