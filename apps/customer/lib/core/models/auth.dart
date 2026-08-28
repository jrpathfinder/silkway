/// Ответы бэкенда на запрос и проверку SMS-кода.
class OtpRequestResult {
  const OtpRequestResult({required this.accepted, required this.phone, required this.expiresInSeconds, this.devCode});

  final bool accepted;
  final String phone;
  final int expiresInSeconds;

  /// Код в открытом виде — только пока бэкенд настроен на мок-провайдер SMS
  /// (см. AuthService.requestOtp). С реальным sms.ru это поле отсутствует.
  final String? devCode;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) => OtpRequestResult(
        accepted: json['accepted'] as bool,
        phone: json['phone'] as String,
        expiresInSeconds: json['expiresInSeconds'] as int,
        devCode: json['devCode'] as String?,
      );
}

class OtpVerifyResult {
  const OtpVerifyResult({required this.verified, this.accessToken, this.refreshToken, this.phone});

  final bool verified;
  final String? accessToken;
  final String? refreshToken;
  final String? phone;

  /// Mirrors `AuthService.verifyOtp`'s two possible shapes exactly:
  /// `{verified:false}` on failure, `{accessToken,refreshToken,user:{phone}}`
  /// on success. Note there is no customer id in either shape — see
  /// SessionNotifier for how customerId is derived until the backend adds one.
  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    if (json['verified'] == false) {
      return const OtpVerifyResult(verified: false);
    }
    return OtpVerifyResult(
      verified: true,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      phone: (json['user'] as Map<String, dynamic>?)?['phone'] as String?,
    );
  }
}
