import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { CatalogService } from '../catalog/catalog.service';
import { LocationsService } from '../locations/locations.service';
import { PaymentProvider } from '../integrations/ports/payment.port';
import { DeliveryAddress, FulfillmentType, Order, OrderStatus } from './order.types';

/// Реальная граница МКАД (не полная административная Москва — та включает
/// Новую Москву далеко на юго-запад) — та же проверка, что и на клиенте
/// (apps/customer/lib/core/models/delivery_zone.dart, MoscowDeliveryZone),
/// намеренно продублирована через границу Dart/TS, а не общий код; правь оба
/// места вместе. Сервер не доверяет клиенту цену и точно так же не должен
/// доверять ему "адрес в зоне доставки".
///
/// Точки — из OSM (маршрут МКАД, relation 2094222), упрощены Дугласом —
/// Пекером с ~2660 узлов дороги до 25 точек.
const MOSCOW_DELIVERY_RING: Array<[number, number]> = [
  [55.75029, 37.36881],
  [55.74098, 37.37171],
  [55.71007, 37.38823],
  [55.66014, 37.43436],
  [55.60019, 37.50455],
  [55.59435, 37.51673],
  [55.57687, 37.58977],
  [55.57184, 37.6666],
  [55.57428, 37.68387],
  [55.60115, 37.75204],
  [55.62193, 37.79082],
  [55.64916, 37.83306],
  [55.65352, 37.83755],
  [55.65889, 37.83977],
  [55.77145, 37.84349],
  [55.82199, 37.8371],
  [55.83127, 37.82568],
  [55.88901, 37.71321],
  [55.89385, 37.70017],
  [55.911, 37.57288],
  [55.90587, 37.52902],
  [55.87174, 37.41367],
  [55.86274, 37.40028],
  [55.84883, 37.39203],
  [55.7847, 37.36997],
];

function isInMoscowDeliveryZone(lat: number, lng: number): boolean {
  let inside = false;
  for (let i = 0, j = MOSCOW_DELIVERY_RING.length - 1; i < MOSCOW_DELIVERY_RING.length; j = i++) {
    const [latI, lngI] = MOSCOW_DELIVERY_RING[i];
    const [latJ, lngJ] = MOSCOW_DELIVERY_RING[j];
    const intersects = latI > lat !== latJ > lat && lng < ((lngJ - lngI) * (lat - latI)) / (latJ - latI) + lngI;
    if (intersects) inside = !inside;
  }
  return inside;
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
    return [...this.orders.values()]
      .filter((order) => order.customerId === customerId)
      .sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }

  /// Без фильтра — все заказы (для панели ресторана). Отдельные action-эндпоинты
  /// (accept/prepare/ready/...) сами проверяют исходный статус, поэтому здесь
  /// достаточно простого списка по статусам, без общего "сменить на любой".
  listByStatuses(statuses?: OrderStatus[]): Order[] {
    const all = [...this.orders.values()];
    if (!statuses || !statuses.length) return all;
    return all.filter((order) => statuses.includes(order.status));
  }

  private transition(orderId: string, from: OrderStatus[], to: OrderStatus): Order {
    const order = this.get(orderId);
    if (!from.includes(order.status)) {
      throw new BadRequestException(`Заказ ${orderId} в статусе ${order.status}, ожидался один из: ${from.join(', ')}`);
    }
    order.status = to;
    return order;
  }

  /// Временная замена реальной обработки платёжного вебхука (см.
  /// IntegrationsController.paymentWebhook — сейчас это заглушка, не
  /// связанная с OrdersService). Без неё заказ никогда не покидает
  /// PENDING_PAYMENT и весь конвейер приёма/готовки/доставки непроверяем.
  markPaidForDemo(orderId: string): Order {
    return this.transition(orderId, ['PENDING_PAYMENT'], 'PAID');
  }

  /// Ресторан принимает заказ в работу.
  accept(orderId: string): Order {
    return this.transition(orderId, ['PAID'], 'ACCEPTED');
  }

  /// Ресторан начинает готовить.
  startPreparing(orderId: string): Order {
    return this.transition(orderId, ['ACCEPTED'], 'PREPARING');
  }

  /// Готово — можно забирать (курьеру или самовывозом).
  markReadyForDelivery(orderId: string): Order {
    return this.transition(orderId, ['PREPARING'], 'READY_FOR_DELIVERY');
  }

  /// Курьер берёт заказ в доставку. Модели назначения конкретного курьера
  /// пока нет — первый принявший забирает заказ из общего пула предложений.
  courierAccept(orderId: string): Order {
    return this.transition(orderId, ['READY_FOR_DELIVERY'], 'IN_DELIVERY');
  }

  /// Курьер подтверждает вручение.
  markDelivered(orderId: string): Order {
    return this.transition(orderId, ['IN_DELIVERY'], 'DELIVERED');
  }
}
