import { BadRequestException } from '@nestjs/common';
import { CatalogService } from '../catalog/catalog.service';
import { LocationsService } from '../locations/locations.service';
import { PaymentProvider } from '../integrations/ports/payment.port';
import { OrdersService } from './orders.service';

class TestPaymentProvider implements PaymentProvider {
  async createPayment() {
    return { id: 'payment-1', status: 'pending' as const, confirmationUrl: 'https://pay.example/1' };
  }
  async refund() {}
}

describe('OrdersService', () => {
  const service = new OrdersService(new CatalogService({ enabled: false } as never), new LocationsService(), new TestPaymentProvider());

  it('takes a server-side price snapshot and is idempotent', async () => {
    const input = { locationId: 'ca-moscow-1', customerId: 'customer-1', lines: [{ itemId: 'plov-classic', quantity: 2 }] };
    const first = await service.create(input, 'same-request');
    const second = await service.create(input, 'same-request');
    expect(first).toBe(second);
    expect(first.totalRub).toBe(1180);
    expect(first.status).toBe('PENDING_PAYMENT');
  });

  it('rejects unavailable or unknown items', async () => {
    await expect(service.create({ locationId: 'ca-moscow-1', customerId: 'customer-1', lines: [{ itemId: 'missing', quantity: 1 }] })).rejects.toThrow(BadRequestException);
  });

  it('creates hosted checkout for an order', async () => {
    const order = await service.create({ locationId: 'ca-moscow-1', customerId: 'customer-2', lines: [{ itemId: 'samsa-lamb', quantity: 1 }] });
    const payment = await service.createCheckout(order.id);
    expect(payment.confirmationUrl).toContain('https://pay.example');
    expect(service.get(order.id).paymentId).toBe('payment-1');
  });
});
