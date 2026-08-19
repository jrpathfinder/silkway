import { Body, Controller, Param, Post } from '@nestjs/common';

@Controller('webhooks')
export class IntegrationsController {
  @Post('payments/:provider')
  paymentWebhook(@Param('provider') provider: string, @Body() payload: Record<string, unknown>) {
    // Production: verify provider signature, persist event id, then process through an outbox.
    return { accepted: true, provider, eventId: payload.id ?? null };
  }

  @Post('delivery/:provider')
  deliveryWebhook(@Param('provider') provider: string, @Body() payload: Record<string, unknown>) {
    return { accepted: true, provider, eventId: payload.id ?? null };
  }
}
