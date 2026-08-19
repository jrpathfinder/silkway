import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { CreatePaymentRequest, PaymentCheckout, PaymentProvider } from '../ports/payment.port';

@Injectable()
export class MockPaymentProvider implements PaymentProvider {
  async createPayment(request: CreatePaymentRequest): Promise<PaymentCheckout> {
    return {
      id: `mock_${randomUUID()}`,
      status: 'pending',
      confirmationUrl: `http://localhost:3000/mock-checkout?orderId=${encodeURIComponent(request.orderId)}`,
    };
  }

  async refund(_paymentId: string, _amountRub?: number): Promise<void> {
    return Promise.resolve();
  }
}
