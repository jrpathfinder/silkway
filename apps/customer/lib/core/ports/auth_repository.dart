import '../models/auth.dart';

abstract class AuthRepository {
  Future<OtpRequestResult> requestOtp(String phone);
  Future<OtpVerifyResult> verifyOtp(String phone, String code);
}
