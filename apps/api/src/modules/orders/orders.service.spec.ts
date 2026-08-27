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

  it('accepts a delivery address inside the Moscow zone', async () => {
    const order = await service.create({
      locationId: 'ca-moscow-1',
      customerId: 'customer-3',
      lines: [{ itemId: 'samsa-lamb', quantity: 1 }],
      fulfillmentType: 'DELIVERY',
      deliveryAddress: { lat: 55.751244, lng: 37.618423, addressText: 'Красная площадь, Москва' },
    });
    expect(order.fulfillmentType).toBe('DELIVERY');
    expect(order.deliveryAddress?.addressText).toBe('Красная площадь, Москва');
  });

  it('rejects a delivery address outside the Moscow zone', async () => {
    await expect(
      service.create({
        locationId: 'ca-moscow-1',
        customerId: 'customer-4',
        lines: [{ itemId: 'samsa-lamb', quantity: 1 }],
        fulfillmentType: 'DELIVERY',
        // Санкт-Петербург — далеко за пределами прямоугольника вокруг Москвы.
        deliveryAddress: { lat: 59.9311, lng: 30.3609, addressText: 'Санкт-Петербург' },
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('does not require a delivery address for pickup', async () => {
    const order = await service.create({
      locationId: 'ca-moscow-1',
      customerId: 'customer-5',
      lines: [{ itemId: 'samsa-lamb', quantity: 1 }],
      fulfillmentType: 'PICKUP',
    });
    expect(order.fulfillmentType).toBe('PICKUP');
    expect(order.deliveryAddress).toBeUndefined();
  });
});
