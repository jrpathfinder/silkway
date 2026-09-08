import { Body, Controller, Get, Header, Param, Post, Query } from '@nestjs/common';

@Controller('webhooks')
export class IntegrationsController {
  // Платёжный вебхук переехал в orders/payment-webhook.controller.ts — ему
  // нужен OrdersService, а сюда он не дотягивается (см. комментарий там).

  @Post('delivery/:provider')
  deliveryWebhook(@Param('provider') provider: string, @Body() payload: Record<string, unknown>) {
    return { accepted: true, provider, eventId: payload.id ?? null };
  }
}

/// MockPaymentProvider.createPayment отправляет клиента именно сюда
/// (confirmationUrl). Настоящий провайдер отдаёт хостинг-страницу платежа —
/// эта страница минимально её имитирует, чтобы поток оплаты в клиенте можно
/// было пройти целиком локально, без ручного вызова mark-paid-demo через
/// curl. Кнопка сама зовёт mark-paid-demo из вебвью — сервер её не трогает
/// (иначе понадобился бы OrdersService здесь, а это цикл orders <-> integrations).
@Controller('mock-checkout')
export class MockCheckoutController {
  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  page(@Query('orderId') orderId: string) {
    return `<!doctype html>
<html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Тестовая оплата</title>
<style>
  body { font-family: -apple-system, sans-serif; padding: 32px 20px; text-align: center; color: #2a211a; }
  button { font-size: 17px; padding: 14px 28px; border-radius: 12px; border: none; background: #c36a3d; color: #fff; margin-top: 24px; }
  button:disabled { opacity: 0.5; }
  p { color: #857d73; }
</style></head>
<body>
  <h2>Тестовая оплата</h2>
  <p>Это мок-страница вместо настоящего платёжного шлюза (см. ADR-002) — в проде здесь будет ЮKassa.</p>
  <button id="pay" onclick="pay()">Оплатить (тест)</button>
  <p id="status"></p>
  <script>
    async function pay() {
      document.getElementById('pay').disabled = true;
      document.getElementById('status').textContent = 'Обрабатываем…';
      try {
        const res = await fetch('/v1/orders/${orderId}/mark-paid-demo', { method: 'POST' });
        if (!res.ok) throw new Error('HTTP ' + res.status);
        document.getElementById('status').textContent = 'Оплачено — можно вернуться в приложение.';
      } catch (e) {
        document.getElementById('status').textContent = 'Не получилось: ' + e;
        document.getElementById('pay').disabled = false;
      }
    }
  </script>
</body></html>`;
  }
}

/// Куда ЮKassa возвращает браузер/вебвью после хостинг-страницы оплаты.
/// Это НЕ источник истины о статусе — просто человекочитаемая точка выхода;
/// статус меняет только вебхук (PaymentWebhookController), а клиент вдобавок
/// сам опрашивает GET /v1/orders/:id, пока открыт экран оплаты.
@Controller('payments/yookassa')
export class YookassaReturnController {
  @Get('return')
  @Header('Content-Type', 'text/html; charset=utf-8')
  page() {
    return `<!doctype html>
<html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Оплата</title>
<style>
  body { font-family: -apple-system, sans-serif; padding: 32px 20px; text-align: center; color: #2a211a; }
  p { color: #857d73; }
</style></head>
<body>
  <h2>Спасибо!</h2>
  <p>Можно вернуться в приложение — статус заказа обновится автоматически.</p>
</body></html>`;
  }
}
