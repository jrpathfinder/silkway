import '../storage/local_kv.dart';

/// Persists an idempotency key per cart "fingerprint" (a caller-supplied
/// deterministic string derived from cart contents) so an app kill-and-relaunch
/// mid-checkout with an unchanged cart reuses the same key — the backend's
/// idempotency map (OrdersService.create) then returns the same order instead
/// of creating a duplicate. A changed fingerprint (edited cart) gets a fresh
/// key.
class IdempotencyKeyStore {
  IdempotencyKeyStore(this._kv);

  final LocalKv _kv;

  String _storageKey(String fingerprint) => 'idempotency_key:$fingerprint';

  Future<String> getOrCreate(String fingerprint, String Function() generateKey) async {
    final storageKey = _storageKey(fingerprint);
    final existing = await _kv.getString(storageKey);
    if (existing != null) return existing;
    final generated = generateKey();
    await _kv.setString(storageKey, generated);
    return generated;
  }

  Future<void> clear(String fingerprint) => _kv.remove(_storageKey(fingerprint));
}
