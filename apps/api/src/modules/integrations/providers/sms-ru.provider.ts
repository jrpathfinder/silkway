import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { SmsProvider } from '../ports/sms.port';

type SmsRuRecipientStatus = { status: string; status_code: number; status_text?: string };
type SmsRuResponse = { status: string; status_code: number; sms?: Record<string, SmsRuRecipientStatus> };

/// https://sms.ru/api/send — GET-запрос с api_id, без подписи запроса.
@Injectable()
export class SmsRuProvider implements SmsProvider {
  private readonly logger = new Logger(SmsRuProvider.name);

  async send(phoneE164: string, message: string): Promise<void> {
    const apiId = process.env.SMS_RU_API_ID;
    if (!apiId) throw new ServiceUnavailableException('SMS_RU_API_ID is not configured');

    // SMS.ru ожидает номер без "+".
    const to = phoneE164.replace(/^\+/, '');
    const url = new URL('https://sms.ru/sms/send');
    url.searchParams.set('api_id', apiId);
    url.searchParams.set('to', to);
    url.searchParams.set('msg', message);
    url.searchParams.set('json', '1');

    const res = await fetch(url);
    const body = (await res.json()) as SmsRuResponse;

    if (body.status !== 'OK') {
      this.logger.error(`SMS.ru rejected the request: status=${body.status} code=${body.status_code}`);
      throw new ServiceUnavailableException('Не удалось отправить SMS');
    }

    const perRecipient = body.sms?.[to];
    if (!perRecipient || perRecipient.status !== 'OK') {
      this.logger.error(`SMS.ru could not deliver to ${to}: ${perRecipient?.status_text ?? perRecipient?.status_code}`);
      throw new ServiceUnavailableException('Не удалось отправить SMS');
    }
  }
}
