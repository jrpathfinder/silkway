import '../../../core/models/auth.dart';
import '../../../core/ports/auth_repository.dart';

/// Мок входа: без сети принимает фиксированный код `0000`.
///
/// Реальный бэкенд больше не имеет такого обхода — он генерирует настоящий
/// 6-значный код и хранит его хеш (см. AuthService.verifyOtp,
/// OtpStore) — так что этот мок нарочно ведёт себя иначе, только для
/// офлайн-разработки без бэкенда.
class AuthRepositoryMock implements AuthRepository {
  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return OtpRequestResult(accepted: true, phone: phone, expiresInSeconds: 300, devCode: '0000');
  }

  @override
  Future<OtpVerifyResult> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
