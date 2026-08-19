import { Module } from '@nestjs/common';
import { PaymentProvider } from './ports/payment.port';
import { MockPaymentProvider } from './providers/mock-payment.provider';
import { IntegrationsController } from './integrations.controller';

@Module({
  controllers: [IntegrationsController],
  providers: [{ provide: PaymentProvider, useClass: MockPaymentProvider }],
  exports: [PaymentProvider],
})
export class IntegrationsModule {}
