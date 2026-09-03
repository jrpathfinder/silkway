import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { CreatePaymentRequest, PaymentCheckout, PaymentProvider } from '../ports/payment.port';

type YookassaPaymentResponse = {
  id: string;
  status: 'pending' | 'waiting_for_capture' | 'succeeded' | 'canceled';
  paid: boolean;
  confirmation?: { confirmation_url: string };
  metadata?: { orderId?: string };
};

function authHeader(shopId: string, secretKey: string): string {
  return `Basic ${Buffer.from(`${shopId}:${secretKey}`).toString('base64')}`;
}

/// https://yookassa.ru/developers/api — REST API, Basic-аутентификация
/// (shopId:secretKey), подтверждение через хостинг-страницу (redirect).
@Injectable()
export class YookassaPaymentProvider implements PaymentProvider {
  private readonly logger = new Logger(YookassaPaymentProvider.name);

  private credentials(): { shopId: string; secretKey: string } {
    const shopId = process.env.YOOKASSA_SHOP_ID;
    const secretKey = process.env.YOOKASSA_SECRET_KEY;
    if (!shopId || !secretKey) {
      throw new ServiceUnavailableException('YOOKASSA_SHOP_ID/YOOKASSA_SECRET_KEY is not configured');
    }
    return { shopId, secretKey };
  }

  async createPayment(request: CreatePaymentRequest): Promise<PaymentCheckout> {
    const { shopId, secretKey } = this.credentials();
    // Возврат в приложение после хостинг-страницы — не источник истины о
    // статусе (пользователь может закрыть вкладку раньше). Статус меняет
    // только вебхук (см. PaymentWebhookController), клиент к тому же сам
    // опрашивает GET /v1/orders/:id, пока открыт экран оплаты.
    const base = process.env.PUBLIC_BASE_URL ?? 'http://localhost:3000';
    const returnUrl = `${base}/v1/payments/yookassa/return`;

    const res = await fetch('https://api.yookassa.ru/v3/payments', {
      method: 'POST',
      headers: {
        Authorization: authHeader(shopId, secretKey),
        'Content-Type': 'application/json',
        'Idempotence-Key': randomUUID(),
      },
      body: JSON.stringify({
        amount: { value: request.amountRub.toFixed(2), currency: 'RUB' },
        confirmation: { type: 'redirect', return_url: returnUrl },
        capture: true,
        description: request.description,
        metadata: { orderId: request.orderId },
      }),
    });

    const body = await res.json();
    if (!res.ok) {
      this.logger.error(`ЮKassa createPayment rejected: ${JSON.stringify(body)}`);
      throw new ServiceUnavailableException('Не удалось создать платёж');
    }
    const payment = body as YookassaPaymentResponse;
    if (!payment.confirmation?.confirmation_url) {
      this.logger.error(`ЮKassa response has no confirmation_url: ${JSON.stringify(payment)}`);
      throw new ServiceUnavailableException('Не удалось создать платёж');
    }

    return {
      id: payment.id,
      status: payment.status === 'succeeded' ? 'succeeded' : payment.status === 'canceled' ? 'cancelled' : 'pending',
      confirmationUrl: payment.confirmation.confirmation_url,
    };
  }

  /// Источник истины для вебхука: ЮKassa не подписывает уведомления, поэтому
  /// тело POST-запроса на вебхук нельзя доверять напрямую — это только
  /// сигнал "проверь". Настоящий статус — только отсюда, по собственным
  /// учётным данным (см. рекомендацию ЮKassa по безопасности вебхуков).
  async getPayment(paymentId: string): Promise<YookassaPaymentResponse> {
    const { shopId, secretKey } = this.credentials();
    const res = await fetch(`https://api.yookassa.ru/v3/payments/${encodeURIComponent(paymentId)}`, {
      headers: { Authorization: authHeader(shopId, secretKey) },
    });
    const body = await res.json();
    if (!res.ok) {
      this.logger.error(`ЮKassa getPayment(${paymentId}) failed: ${JSON.stringify(body)}`);
      throw new ServiceUnavailableException('Не удалось проверить платёж');
    }
    return body as YookassaPaymentResponse;
  }

  async refund(paymentId: string, amountRub?: number): Promise<void> {
    const { shopId, secretKey } = this.credentials();
    if (amountRub === undefined) {
      throw new ServiceUnavailableException('amountRub is required for a ЮKassa refund');
    }

    const res = await fetch('https://api.yookassa.ru/v3/refunds', {
      method: 'POST',
      headers: {
        Authorization: authHeader(shopId, secretKey),
        'Content-Type': 'application/json',
        'Idempotence-Key': randomUUID(),
      },
      body: JSON.stringify({
        payment_id: paymentId,
        amount: { value: amountRub.toFixed(2), currency: 'RUB' },
      }),
    });

    if (!res.ok) {
      const body = await res.json();
      this.logger.error(`ЮKassa refund rejected: ${JSON.stringify(body)}`);
      throw new ServiceUnavailableException('Не удалось выполнить возврат');
    }
  }
}
