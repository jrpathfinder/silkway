import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/auth.dart';

void main() {
  group('OtpRequestResult', () {
    test('fromJson parses all fields', () {
      final result = OtpRequestResult.fromJson({'accepted': true, 'phone': '+79990000000', 'expiresInSeconds': 300});
      expect(result.accepted, isTrue);
      expect(result.phone, '+79990000000');
      expect(result.expiresInSeconds, 300);
    });
  });

  group('OtpVerifyResult', () {
    test('fromJson returns unverified for {verified:false}', () {
      final result = OtpVerifyResult.fromJson({'verified': false});
      expect(result.verified, isFalse);
      expect(result.accessToken, isNull);
      expect(result.phone, isNull);
    });

    test('fromJson parses tokens and nested user.phone on success', () {
      final result = OtpVerifyResult.fromJson({
        'accessToken': 'dev-access-token',
        'refreshToken': 'dev-refresh-token',
        'user': {'phone': '+79990000000'},
      });
      expect(result.verified, isTrue);
      expect(result.accessToken, 'dev-access-token');
      expect(result.refreshToken, 'dev-refresh-token');
      expect(result.phone, '+79990000000');
    });

    test('fromJson tolerates a missing user object', () {
      final result = OtpVerifyResult.fromJson({'accessToken': 'a', 'refreshToken': 'b'});
      expect(result.verified, isTrue);
      expect(result.phone, isNull);
    });
  });
}
