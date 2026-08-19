import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {
  requestOtp(phone: string) {
    // Production: persist a hashed OTP in Redis and send through an approved SMS provider.
    return { accepted: true, phone, expiresInSeconds: Number(process.env.OTP_TTL_SECONDS ?? 300) };
  }

  verifyOtp(phone: string, code: string) {
    // Development-only deterministic flow. Replace before production.
    const verified = process.env.NODE_ENV === 'production' ? false : code === '0000';
    return verified
      ? { accessToken: 'dev-access-token', refreshToken: 'dev-refresh-token', user: { phone } }
      : { verified: false };
  }
}
