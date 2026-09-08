import { Module } from '@nestjs/common';
import { PaymentProvider } from './ports/payment.port';
import { MockPaymentProvider } from './providers/mock-payment.provider';
import { YookassaPaymentProvider } from './providers/yookassa-payment.provider';
import { SmsProvider } from './ports/sms.port';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { SmsRuProvider } from './providers/sms-ru.provider';
import { IntegrationsController, MockCheckoutController, YookassaReturnController } from './integrations.controller';

@Module({
  controllers: [IntegrationsController, MockCheckoutController, YookassaReturnController],
  providers: [
    YookassaPaymentProvider,
    // PAYMENT_PROVIDER=yookassa requires YOOKASSA_SHOP_ID/YOOKASSA_SECRET_KEY
    // — otherwise stays Mock, same enabled/fallback shape as SmsProvider.
    // YookassaPaymentProvider is also registered under its own token above:
    // PaymentWebhookController needs it directly (getPayment isn't part of
    // the generic PaymentProvider port — webhook verification is inherently
    // provider-specific, doesn't fit a generic abstraction).
    { provide: PaymentProvider, useClass: process.env.PAYMENT_PROVIDER === 'yookassa' ? YookassaPaymentProvider : MockPaymentProvider },
    { provide: SmsProvider, useClass: process.env.SMS_PROVIDER === 'sms.ru' ? SmsRuProvider : MockSmsProvider },
  ],
  exports: [PaymentProvider, SmsProvider, YookassaPaymentProvider],
})
export class IntegrationsModule {}
