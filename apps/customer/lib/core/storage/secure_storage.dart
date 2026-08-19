import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh token storage (Keychain on iOS, EncryptedSharedPreferences
/// on Android). Never use [LocalKv]/shared_preferences for tokens.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'silkway.accessToken';
  static const _refreshTokenKey = 'silkway.refreshToken';
  static const _phoneKey = 'silkway.phone';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String phone,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _phoneKey, value: phone),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readPhone() => _storage.read(key: _phoneKey);

  Future<bool> hasSession() async => (await readAccessToken()) != null;

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _phoneKey),
    ]);
  }
}
