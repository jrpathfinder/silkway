import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:silkway_app/app/flavor.dart';
import 'package:silkway_app/core/env/env.dart';
import 'package:silkway_app/core/providers.dart';
import 'package:silkway_app/core/storage/local_kv.dart';
import 'package:silkway_app/core/storage/secure_storage.dart';

/// In-memory [SecureStorage] double — every method is overridden so no test
/// ever touches the real `flutter_secure_storage` platform channel (which
/// isn't registered under `flutter test`).
class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> saveSession({required String accessToken, required String refreshToken, required String phone}) async {
    _values['accessToken'] = accessToken;
    _values['refreshToken'] = refreshToken;
    _values['phone'] = phone;
  }

  @override
  Future<String?> readAccessToken() async => _values['accessToken'];

  @override
  Future<String?> readPhone() async => _values['phone'];

  @override
  Future<bool> hasSession() async => _values['accessToken'] != null;

  @override
  Future<void> clearSession() async {
    _values.remove('accessToken');
    _values.remove('refreshToken');
    _values.remove('phone');
  }
}

/// In-memory [LocalKv] double — same rationale as [FakeSecureStorage], for
/// `shared_preferences`.
class FakeLocalKv extends LocalKv {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

/// The env used by every test that wants mock repositories (the default app
/// behavior — see Env.useMocks).
const testMockEnv = Env(apiBaseUrl: 'http://localhost:3000', useMocks: true, flavor: AppFlavor.customer);

/// Standard override set for widget/provider tests: mocked repositories plus
/// fake storage so nothing hits a real platform channel. Pass a pre-seeded
/// [secureStorage]/[localKv] when a test needs to control their contents.
List<Override> testOverrides({Env env = testMockEnv, FakeSecureStorage? secureStorage, FakeLocalKv? localKv}) => [
      envProvider.overrideWithValue(env),
      secureStorageProvider.overrideWithValue(secureStorage ?? FakeSecureStorage()),
      localKvProvider.overrideWithValue(localKv ?? FakeLocalKv()),
    ];

/// A [HttpClientAdapter] double for testing `*RepositoryHttp` classes without
/// a real network call — install it on an [ApiClient]'s `dio.httpClientAdapter`.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.responder);

  /// Given the request, return (statusCode, jsonBody). Throw to simulate a
  /// network/parsing failure.
  final (int, String) Function(RequestOptions options) responder;

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    final (statusCode, body) = responder(options);
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
