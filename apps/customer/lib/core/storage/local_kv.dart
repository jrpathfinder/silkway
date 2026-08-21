import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret local key-value state: idempotency keys, locale override,
/// last-selected location id, onboarding-seen flags. Never tokens — see
/// [SecureStorage] for those.
class LocalKv {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getString(String key) async => (await _prefs).getString(key);

  Future<void> setString(String key, String value) async => (await _prefs).setString(key, value);

  Future<void> remove(String key) async => (await _prefs).remove(key);
}
