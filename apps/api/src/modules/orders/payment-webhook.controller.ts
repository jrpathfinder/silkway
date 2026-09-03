import { Body, Controller, Logger, Param, Post } from '@nestjs/common';
import { YookassaPaymentProvider } from '../integrations/providers/yookassa-payment.provider';
import { OrdersService } from './orders.service';

/// Живёт в orders/, а не в integrations/ — обработка вебхука меняет статус
/// заказа, для этого нужен OrdersService. IntegrationsModule его не видит:
/// OrdersModule уже импортирует IntegrationsModule (за PaymentProvider), а
/// обратный импорт создал бы цикл. YookassaPaymentProvider доступен здесь
/// напрямую (см. IntegrationsModule.exports).
@Controller('webhooks/payments')
export class PaymentWebhookController {
  private readonly logger = new Logger(PaymentWebhookController.name);

  constructor(
    private readonly orders: OrdersService,
    private readonly yookassa: YookassaPaymentProvider,
  ) {}

  @Post(':provider')
  async handle(@Param('provider') provider: string, @Body() payload: { object?: { id?: string } }) {
    if (provider !== 'yookassa') {
      // Другие провайдеры пока не подключены — тихо принимаем, чтобы
      // отправитель не ретраил бесконечно, но ничего не меняем.
      return { accepted: true, provider };
    }

    const paymentId = payload.object?.id;
    if (!paymentId) return { accepted: true, provider };

    // Тело вебхука не подписано ЮKassa — это только сигнал "проверь".
    // Настоящий статус берём отдельным запросом по своим учётным данным.
    const payment = await this.yookassa.getPayment(paymentId);
    if (payment.status !== 'succeeded' || !payment.paid) {
      return { accepted: true, provider };
    }

    const orderId = payment.metadata?.orderId;
    if (!orderId) {
      this.logger.warn(`ЮKassa payment ${paymentId} succeeded but has no metadata.orderId`);
      return { accepted: true, provider };
    }

    try {
      this.orders.markPaidForDemo(orderId);
    } catch (error) {
      // Например, повторный вебхук после того, как заказ уже не в
      // PENDING_PAYMENT — не ошибка на нашей стороне, просто дубликат.
      this.logger.warn(`Could not mark order ${orderId} paid from webhook: ${error}`);
    }

    return { accepted: true, provider };
  }
}
