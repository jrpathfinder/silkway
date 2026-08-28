import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { CreatePaymentRequest, PaymentCheckout, PaymentProvider } from '../ports/payment.port';

@Injectable()
export class MockPaymentProvider implements PaymentProvider {
  async createPayment(request: CreatePaymentRequest): Promise<PaymentCheckout> {
    // localhost только годится когда клиент и бэкенд на одной машине
    // (симулятор). Физическое устройство идёт по LAN/hotspot-адресу — тому
    // же, что задан клиенту через --dart-define=API_BASE_URL — так что этот
    // адрес нужно держать в синхроне с ним при локальном тестировании.
    const base = process.env.PUBLIC_BASE_URL ?? 'http://localhost:3000';
    return {
      id: `mock_${randomUUID()}`,
      status: 'pending',
      confirmationUrl: `${base}/v1/mock-checkout?orderId=${encodeURIComponent(request.orderId)}`,
    };
  }

  async refund(_paymentId: string, _amountRub?: number): Promise<void> {
    return Promise.resolve();
  }
}
