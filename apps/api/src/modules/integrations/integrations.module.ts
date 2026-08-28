import { Module } from '@nestjs/common';
import { PaymentProvider } from './ports/payment.port';
import { MockPaymentProvider } from './providers/mock-payment.provider';
import { SmsProvider } from './ports/sms.port';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { SmsRuProvider } from './providers/sms-ru.provider';
import { IntegrationsController, MockCheckoutController } from './integrations.controller';

@Module({
  controllers: [IntegrationsController, MockCheckoutController],
  providers: [
    { provide: PaymentProvider, useClass: MockPaymentProvider },
    // SMS_PROVIDER=sms.ru requires SMS_RU_API_ID — otherwise stays Mock
    // (logs the code instead of sending it), same enabled/fallback shape as
    // DatabaseService.
    { provide: SmsProvider, useClass: process.env.SMS_PROVIDER === 'sms.ru' ? SmsRuProvider : MockSmsProvider },
  ],
  exports: [PaymentProvider, SmsProvider],
})
export class IntegrationsModule {}
