import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/network/api_client.dart';
import 'package:silkway_app/features/auth/data/auth_repository_http.dart';

import '../helpers/fakes.dart';

void main() {
  test('requestOtp POSTs the phone and unwraps `data`', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/auth/otp/request');
      expect(options.data, {'phone': '+79990000000'});
      return (200, '{"data": {"accepted": true, "phone": "+79990000000", "expiresInSeconds": 300}}');
    });

    final repo = AuthRepositoryHttp(client);
    final result = await repo.requestOtp('+79990000000');

    expect(result.accepted, isTrue);
  });

  test('verifyOtp POSTs the phone and code and unwraps `data`', () async {
    final client = ApiClient(testMockEnv, FakeSecureStorage());
    client.dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, '/v1/auth/otp/verify');
      expect(options.data, {'phone': '+79990000000', 'code': '0000'});
      return (200, '{"data": {"accessToken": "a", "refreshToken": "b", "user": {"phone": "+79990000000"}}}');
    });

    final repo = AuthRepositoryHttp(client);
    final result = await repo.verifyOtp('+79990000000', '0000');

    expect(result.verified, isTrue);
    expect(result.accessToken, 'a');
  });
}
