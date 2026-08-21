import '../../../core/models/auth.dart';
import '../../../core/ports/auth_repository.dart';

/// Мок входа. Повторяет dev-поведение бэкенда: подходит только код `0000`.
class AuthRepositoryMock implements AuthRepository {
  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return OtpRequestResult(accepted: true, phone: phone, expiresInSeconds: 300);
  }

  @override
  Future<OtpVerifyResult> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Matches the backend dev-stub exactly: hardcoded code 0000 outside prod
    // (AuthService.verifyOtp) — so mock and real dev backend behave identically.
    if (code == '0000') {
      return OtpVerifyResult(
        verified: true,
        accessToken: 'dev-access-token',
        refreshToken: 'dev-refresh-token',
        phone: phone,
      );
    }
    return const OtpVerifyResult(verified: false);
  }
}
