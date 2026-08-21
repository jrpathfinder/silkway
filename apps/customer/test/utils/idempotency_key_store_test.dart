import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/utils/idempotency_key_store.dart';

import '../helpers/fakes.dart';

void main() {
  test('getOrCreate generates and persists a key for a new fingerprint', () async {
    final store = IdempotencyKeyStore(FakeLocalKv());
    var calls = 0;
    final key = await store.getOrCreate('fp-1', () {
      calls++;
      return 'generated-key';
    });

    expect(key, 'generated-key');
    expect(calls, 1);
  });

  test('getOrCreate reuses the persisted key on a second call with the same fingerprint', () async {
    final kv = FakeLocalKv();
    final store = IdempotencyKeyStore(kv);
    final first = await store.getOrCreate('fp-1', () => 'key-a');
    var secondGeneratorCalled = false;
    final second = await store.getOrCreate('fp-1', () {
      secondGeneratorCalled = true;
      return 'key-b';
    });

    expect(second, first);
    expect(secondGeneratorCalled, isFalse);
  });

  test('clear removes the stored key so the next getOrCreate generates a fresh one', () async {
    final kv = FakeLocalKv();
    final store = IdempotencyKeyStore(kv);
    await store.getOrCreate('fp-1', () => 'key-a');
    await store.clear('fp-1');

    final regenerated = await store.getOrCreate('fp-1', () => 'key-b');
    expect(regenerated, 'key-b');
  });
}
