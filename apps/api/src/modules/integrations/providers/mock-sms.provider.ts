import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider } from '../ports/sms.port';

/// Не отправляет ничего — печатает код в лог сервера. Так локальная
/// разработка/тесты проходят тем же путём генерации и проверки кода, что и
/// продакшен (см. OtpStore), просто без реальной отправки SMS.
@Injectable()
export class MockSmsProvider implements SmsProvider {
  private readonly logger = new Logger(MockSmsProvider.name);

  async send(phoneE164: string, message: string): Promise<void> {
    this.logger.log(`[mock sms -> ${phoneE164}] ${message}`);
  }
}
