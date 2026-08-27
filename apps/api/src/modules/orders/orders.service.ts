import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { CatalogService } from '../catalog/catalog.service';
import { LocationsService } from '../locations/locations.service';
import { PaymentProvider } from '../integrations/ports/payment.port';
import { DeliveryAddress, FulfillmentType, Order } from './order.types';

/// Грубый прямоугольник вокруг Москвы — та же приближённая проверка, что и
/// на клиенте (apps/customer/lib/core/models/delivery_zone.dart,
/// MoscowDeliveryZone) — намеренно продублирована через границу Dart/TS, а
/// не общий код; правь оба места вместе. Сервер не доверяет клиенту цену и
/// точно так же не должен доверять ему "адрес в зоне доставки".
const MOSCOW_DELIVERY_ZONE = { minLat: 55.48, maxLat: 55.95, minLng: 37.25, maxLng: 37.95 };

function isInMoscowDeliveryZone(lat: number, lng: number): boolean {
  return (
    lat >= MOSCOW_DELIVERY_ZONE.minLat &&
    lat <= MOSCOW_DELIVERY_ZONE.maxLat &&
    lng >= MOSCOW_DELIVERY_ZONE.minLng &&
    lng <= MOSCOW_DELIVERY_ZONE.maxLng
  );
}

type CreateOrderInput = {
  locationId: string;
  customerId: string;
  lines: Array<{ itemId: string; quantity: number; modifierIds?: string[] }>;
  /// Опционально ради обратной совместимости (существующие тесты не задают
  /// его) — реальный клиент всегда передаёт явно, по умолчанию 'DELIVERY'.
  fulfillmentType?: FulfillmentType;
  deliveryAddress?: DeliveryAddress;
};

@Injectable()
export class OrdersService {
  private readonly orders = new Map<string, Order>();
  private readonly idempotency = new Map<string, string>();

  constructor(
    private readonly catalog: CatalogService,
    private readonly locations: LocationsService,
    private readonly payments: PaymentProvider,
  ) {}

  async create(input: CreateOrderInput, idempotencyKey?: string): Promise<Order> {
    if (idempotencyKey && this.idempotency.has(idempotencyKey)) {
      return this.orders.get(this.idempotency.get(idempotencyKey)!)!;
    }
    if (!this.locations.getById(input.locationId)) throw new BadRequestException('Unknown location');

    const fulfillmentType = input.fulfillmentType ?? 'DELIVERY';
    if (fulfillmentType === 'DELIVERY' && input.deliveryAddress) {
      const { lat, lng } = input.deliveryAddress;
      if (!isInMoscowDeliveryZone(lat, lng)) {
        throw new BadRequestException('Мы не доставляем в этот район');
      }
    }

    const catalog = await this.catalog.getForLocation(input.locationId);
    const lines = input.lines.map((line) => {
      const item = catalog.items.find((candidate) => candidate.id === line.itemId);
      if (!item || !item.isAvailable) throw new BadRequestException(`Item unavailable: ${line.itemId}`);
      if (!Number.isInteger(line.quantity) || line.quantity < 1 || line.quantity > 20) {
        throw new BadRequestException('Quantity must be between 1 and 20');
      }
      const modifiers = (line.modifierIds ?? []).map((modifierId) => {
        const modifier = item.modifiers.find((candidate) => candidate.id === modifierId);
        if (!modifier) throw new BadRequestException(`Unknown modifier: ${modifierId}`);
        return modifier;
      });
      return {
        itemId: item.id,
        name: item.name,
        quantity: line.quantity,
        unitPriceRub: item.priceRub + modifiers.reduce((sum, modifier) => sum + modifier.priceRub, 0),
        modifierIds: modifiers.map((modifier) => modifier.id),
      };
    });
    if (!lines.length) throw new BadRequestException('Order must contain at least one item');

    const order: Order = {
      id: randomUUID(),
      locationId: input.locationId,
      customerId: input.customerId,
      lines,
      totalRub: lines.reduce((sum, line) => sum + line.unitPriceRub * line.quantity, 0),
      status: 'PENDING_PAYMENT',
      createdAt: new Date().toISOString(),
      fulfillmentType,
      deliveryAddress: input.deliveryAddress,
    };
    this.orders.set(order.id, order);
    if (idempotencyKey) this.idempotency.set(idempotencyKey, order.id);
    return order;
  }

  async createCheckout(orderId: string) {
    const order = this.get(orderId);
    const payment = await this.payments.createPayment({
      orderId: order.id,
      amountRub: order.totalRub,
      description: `Заказ ${order.id}`,
    });
    order.paymentId = payment.id;
    return payment;
  }

  get(id: string): Order {
    const order = this.orders.get(id);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  listForCustomer(customerId: string): Order[] {
    return [...this.orders.values()].filter((order) => order.customerId === customerId);
  }
}
