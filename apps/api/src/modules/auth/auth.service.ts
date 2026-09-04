import { Injectable } from '@nestjs/common';
import { SmsProvider } from '../integrations/ports/sms.port';
import { OtpStore } from './otp-store.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly sms: SmsProvider,
    private readonly otpStore: OtpStore,
  ) {}

  async requestOtp(phone: string) {
    const expiresInSeconds = Number(process.env.OTP_TTL_SECONDS ?? 300);
    const result = await this.otpStore.generateAndStore(phone, expiresInSeconds);
    if (!result.allowed) {
      // accepted:false с валидным expiresInSeconds — контракт с клиентом не
      // меняется (OtpRequestResult.fromJson требует это поле всегда).
      return { accepted: false, phone, expiresInSeconds, retryAfterSeconds: result.retryAfterSeconds };
    }

    await this.sms.send(phone, `Код подтверждения Шёлковый Путь: ${result.code}`);
    // Код в ответе только пока провайдер не настоящий (sms.ru): реальная SMS
    // и так его доставит, а этот флаг только избавляет от чтения логов
    // бэкенда при локальном тестировании. С sms.ru это поле не появляется.
    const devCode = process.env.SMS_PROVIDER === 'sms.ru' ? undefined : result.code;
    return { accepted: true, phone, expiresInSeconds, devCode };
  }

  async verifyOtp(phone: string, code: string) {
    const verified = await this.otpStore.verify(phone, code);
    // Реальная сессия/JWT — отдельная, ещё не сделанная задача (см. ADR-003
    // про отсутствие customerId в этом ответе); здесь чинится только
    // генерация/доставка/проверка кода.
    return verified
      ? { accessToken: 'dev-access-token', refreshToken: 'dev-refresh-token', user: { phone } }
      : { verified: false };
  }
}
