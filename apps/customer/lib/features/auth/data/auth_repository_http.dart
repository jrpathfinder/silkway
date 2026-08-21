import '../../../core/models/auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/auth_repository.dart';

/// Вход по SMS-коду через бэкенд.
///
/// На стороне сервера это пока dev-заглушка: код `0000`, статические токены,
/// никакой реальной сессии (см. AuthService.verifyOtp).
class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    final res = await _client.dio.post('/v1/auth/otp/request', data: {'phone': phone});
    return OtpRequestResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<OtpVerifyResult> verifyOtp(String phone, String code) async {
    final res = await _client.dio.post('/v1/auth/otp/verify', data: {'phone': phone, 'code': code});
    return OtpVerifyResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
