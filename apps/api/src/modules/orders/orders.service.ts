import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { DatabaseService } from '../../database/database.service';
import { CatalogService } from '../catalog/catalog.service';
import { LocationsService } from '../locations/locations.service';
import { PaymentProvider } from '../integrations/ports/payment.port';
import { DeliveryAddress, FulfillmentType, Order, OrderLine, OrderStatus } from './order.types';

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

const POSTGRES_UNIQUE_VIOLATION = '23505';

type CreateOrderInput = {
  locationId: string;
  customerId: string;
  lines: Array<{ itemId: string; quantity: number; modifierIds?: string[] }>;
  /// Опционально ради обратной совместимости (существующие тесты не задают
  /// его) — реальный клиент всегда передаёт явно, по умолчанию 'DELIVERY'.
  fulfillmentType?: FulfillmentType;
  deliveryAddress?: DeliveryAddress;
};

type OrderDetails = {
  lines: OrderLine[];
  fulfillmentType: FulfillmentType;
  deliveryAddress?: DeliveryAddress;
};

type OrderRow = {
  id: string;
  location_id: string;
  customer_id: string;
  status: OrderStatus;
  total_minor: string;
  payment_id: string | null;
  created_at: Date;
  details: OrderDetails;
};

@Injectable()
export class OrdersService {
  private readonly orders = new Map<string, Order>();
  private readonly idempotency = new Map<string, string>();

  constructor(
    private readonly catalog: CatalogService,
    private readonly locations: LocationsService,
    private readonly payments: PaymentProvider,
    private readonly database: DatabaseService,
  ) {}

  async create(input: CreateOrderInput, idempotencyKey?: string): Promise<Order> {
    return this.database.enabled ? this.createSql(input, idempotencyKey) : this.createMemory(input, idempotencyKey);
  }

  async createCheckout(orderId: string): Promise<Awaited<ReturnType<PaymentProvider['createPayment']>>> {
    return this.database.enabled ? this.createCheckoutSql(orderId) : this.createCheckoutMemory(orderId);
  }

  async get(id: string): Promise<Order> {
    return this.database.enabled ? this.getSql(id) : this.getMemory(id);
  }

  async listForCustomer(customerId: string): Promise<Order[]> {
    return this.database.enabled ? this.listForCustomerSql(customerId) : this.listForCustomerMemory(customerId);
  }

  /// Без фильтра — все заказы (для панели ресторана). Отдельные action-эндпоинты
  /// (accept/prepare/ready/...) сами проверяют исходный статус, поэтому здесь
  /// достаточно простого списка по статусам, без общего "сменить на любой".
  async listByStatuses(statuses?: OrderStatus[]): Promise<Order[]> {
    return this.database.enabled ? this.listByStatusesSql(statuses) : this.listByStatusesMemory(statuses);
  }

  /// Временная замена реальной обработки платёжного вебхука (см.
  /// PaymentWebhookController — обрабатывает только ЮKassa; для мок-режима
  /// это единственный способ подтвердить оплату). Без неё заказ никогда не
  /// покидает PENDING_PAYMENT и весь конвейер приёма/готовки/доставки
  /// непроверяем.
  async markPaidForDemo(orderId: string): Promise<Order> {
    return this.transition(orderId, ['PENDING_PAYMENT'], 'PAID');
  }

  /// Ресторан принимает заказ в работу.
  async accept(orderId: string): Promise<Order> {
    return this.transition(orderId, ['PAID'], 'ACCEPTED');
  }

  /// Ресторан начинает готовить.
  async startPreparing(orderId: string): Promise<Order> {
    return this.transition(orderId, ['ACCEPTED'], 'PREPARING');
  }

  /// Готово — можно забирать (курьеру или самовывозом).
  async markReadyForDelivery(orderId: string): Promise<Order> {
    return this.transition(orderId, ['PREPARING'], 'READY_FOR_DELIVERY');
  }

  /// Курьер берёт заказ в доставку. Модели назначения конкретного курьера
  /// пока нет — первый принявший забирает заказ из общего пула предложений.
  async courierAccept(orderId: string): Promise<Order> {
    return this.transition(orderId, ['READY_FOR_DELIVERY'], 'IN_DELIVERY');
  }

  /// Курьер подтверждает вручение.
  async markDelivered(orderId: string): Promise<Order> {
    return this.transition(orderId, ['IN_DELIVERY'], 'DELIVERED');
  }

  private async transition(orderId: string, from: OrderStatus[], to: OrderStatus): Promise<Order> {
    return this.database.enabled ? this.transitionSql(orderId, from, to) : this.transitionMemory(orderId, from, to);
  }

  // ---------------------------------------------------------------------
  // Postgres-backed path. Survives an API restart, unlike the in-memory
  // fallback below — see DatabaseService.enabled.
  // ---------------------------------------------------------------------

  private async createSql(input: CreateOrderInput, idempotencyKey?: string): Promise<Order> {
    if (idempotencyKey) {
      const existing = await this.findByIdempotencyKey(idempotencyKey);
      if (existing) return existing;
    }
    if (!this.locations.getById(input.locationId)) throw new BadRequestException('Unknown location');

    const fulfillmentType = input.fulfillmentType ?? 'DELIVERY';
    this.assertDeliveryZone(fulfillmentType, input.deliveryAddress);

    const catalog = await this.catalog.getForLocation(input.locationId);
    const lines = this.buildOrderLines(input.lines, catalog);
    const totalRub = this.sumTotal(lines);
    const id = randomUUID();
    const createdAt = new Date().toISOString();
    const details: OrderDetails = { lines, fulfillmentType, deliveryAddress: input.deliveryAddress };

    // order_header.customer_id is a real FK — nothing else in this codebase
    // creates `customer` rows yet (AuthService's session is still a stub;
    // the client uses the phone number as the id — see ADR-003), so upsert
    // one here using the phone number as its own natural key.
    await this.database.query(`insert into customer (id, phone_e164) values ($1, $1) on conflict (id) do nothing`, [input.customerId]);

    try {
      await this.database.query(
        `insert into order_header (id, location_id, customer_id, status, total_minor, idempotency_key, details, created_at)
         values ($1, $2, $3, 'PENDING_PAYMENT', $4, $5, $6, $7)`,
        [id, input.locationId, input.customerId, Math.round(totalRub * 100), idempotencyKey ?? null, JSON.stringify(details), createdAt],
      );
    } catch (error) {
      // A concurrent request with the same idempotency key won the race —
      // return what it created instead of erroring.
      if (idempotencyKey && this.isUniqueViolation(error)) {
        const existing = await this.findByIdempotencyKey(idempotencyKey);
        if (existing) return existing;
      }
      throw error;
    }

    return { id, locationId: input.locationId, customerId: input.customerId, lines, totalRub, status: 'PENDING_PAYMENT', createdAt, fulfillmentType, deliveryAddress: input.deliveryAddress };
  }

  private async createCheckoutSql(orderId: string) {
    const order = await this.getSql(orderId);
    const payment = await this.payments.createPayment({ orderId: order.id, amountRub: order.totalRub, description: `Заказ ${order.id}` });
    await this.database.query(`update order_header set payment_id = $1, payment_provider = $2 where id = $3`, [
      payment.id,
      process.env.PAYMENT_PROVIDER ?? 'mock',
      order.id,
    ]);
    return payment;
  }

  private async getSql(id: string): Promise<Order> {
    const result = await this.database.query<OrderRow>(`select * from order_header where id = $1`, [id]);
    if (!result.rows.length) throw new NotFoundException('Order not found');
    return this.mapRow(result.rows[0]);
  }

  private async listForCustomerSql(customerId: string): Promise<Order[]> {
    const result = await this.database.query<OrderRow>(`select * from order_header where customer_id = $1 order by created_at desc`, [customerId]);
    return result.rows.map((row) => this.mapRow(row));
  }

  private async listByStatusesSql(statuses?: OrderStatus[]): Promise<Order[]> {
    const result = statuses?.length
      ? await this.database.query<OrderRow>(`select * from order_header where status = any($1) order by created_at desc`, [statuses])
      : await this.database.query<OrderRow>(`select * from order_header order by created_at desc`);
    return result.rows.map((row) => this.mapRow(row));
  }

  private async transitionSql(orderId: string, from: OrderStatus[], to: OrderStatus): Promise<Order> {
    const result = await this.database.query<OrderRow>(`update order_header set status = $1 where id = $2 and status = any($3) returning *`, [
      to,
      orderId,
      from,
    ]);
    if (result.rows.length) return this.mapRow(result.rows[0]);

    // 0 rows: either the order doesn't exist, or it exists but wasn't in an
    // eligible starting status — re-fetch (throws NotFoundException itself
    // if missing) to tell those two cases apart for the error.
    const current = await this.getSql(orderId);
    throw new BadRequestException(`Заказ ${orderId} в статусе ${current.status}, ожидался один из: ${from.join(', ')}`);
  }

  private async findByIdempotencyKey(idempotencyKey: string): Promise<Order | undefined> {
    const result = await this.database.query<OrderRow>(`select * from order_header where idempotency_key = $1`, [idempotencyKey]);
    return result.rows.length ? this.mapRow(result.rows[0]) : undefined;
  }

  private isUniqueViolation(error: unknown): boolean {
    return typeof error === 'object' && error !== null && (error as { code?: string }).code === POSTGRES_UNIQUE_VIOLATION;
  }

  private mapRow(row: OrderRow): Order {
    return {
      id: row.id,
      locationId: row.location_id,
      customerId: row.customer_id,
      lines: row.details.lines,
      totalRub: Number(row.total_minor) / 100,
      status: row.status,
      createdAt: row.created_at.toISOString(),
      paymentId: row.payment_id ?? undefined,
      fulfillmentType: row.details.fulfillmentType,
      deliveryAddress: row.details.deliveryAddress,
    };
  }

  // ---------------------------------------------------------------------
  // In-process fallback — used when DATABASE_URL isn't set (unit tests,
  // quick local runs). Lost on every restart; see DatabaseService.enabled.
  // ---------------------------------------------------------------------

  private async createMemory(input: CreateOrderInput, idempotencyKey?: string): Promise<Order> {
    if (idempotencyKey && this.idempotency.has(idempotencyKey)) {
      return this.orders.get(this.idempotency.get(idempotencyKey)!)!;
    }
    if (!this.locations.getById(input.locationId)) throw new BadRequestException('Unknown location');

    const fulfillmentType = input.fulfillmentType ?? 'DELIVERY';
    this.assertDeliveryZone(fulfillmentType, input.deliveryAddress);

    const catalog = await this.catalog.getForLocation(input.locationId);
    const lines = this.buildOrderLines(input.lines, catalog);

    const order: Order = {
      id: randomUUID(),
      locationId: input.locationId,
      customerId: input.customerId,
      lines,
      totalRub: this.sumTotal(lines),
      status: 'PENDING_PAYMENT',
      createdAt: new Date().toISOString(),
      fulfillmentType,
      deliveryAddress: input.deliveryAddress,
    };
    this.orders.set(order.id, order);
    if (idempotencyKey) this.idempotency.set(idempotencyKey, order.id);
    return order;
  }

  private async createCheckoutMemory(orderId: string) {
    const order = this.getMemory(orderId);
    const payment = await this.payments.createPayment({ orderId: order.id, amountRub: order.totalRub, description: `Заказ ${order.id}` });
    order.paymentId = payment.id;
    return payment;
  }

  private getMemory(id: string): Order {
    const order = this.orders.get(id);
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  private listForCustomerMemory(customerId: string): Order[] {
    return [...this.orders.values()].filter((order) => order.customerId === customerId).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }

  private listByStatusesMemory(statuses?: OrderStatus[]): Order[] {
    const all = [...this.orders.values()];
    if (!statuses || !statuses.length) return all;
    return all.filter((order) => statuses.includes(order.status));
  }

  private transitionMemory(orderId: string, from: OrderStatus[], to: OrderStatus): Order {
    const order = this.getMemory(orderId);
    if (!from.includes(order.status)) {
      throw new BadRequestException(`Заказ ${orderId} в статусе ${order.status}, ожидался один из: ${from.join(', ')}`);
    }
    order.status = to;
    return order;
  }

  // ---------------------------------------------------------------------
  // Shared by both paths.
  // ---------------------------------------------------------------------

  private assertDeliveryZone(fulfillmentType: FulfillmentType, deliveryAddress?: DeliveryAddress): void {
    if (fulfillmentType !== 'DELIVERY' || !deliveryAddress) return;
    if (!isInMoscowDeliveryZone(deliveryAddress.lat, deliveryAddress.lng)) {
      throw new BadRequestException('Мы не доставляем в этот район');
    }
  }

  private buildOrderLines(requested: CreateOrderInput['lines'], catalog: Awaited<ReturnType<CatalogService['getForLocation']>>): OrderLine[] {
    const lines = requested.map((line) => {
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
    return lines;
  }

  private sumTotal(lines: OrderLine[]): number {
    return lines.reduce((sum, line) => sum + line.unitPriceRub * line.quantity, 0);
  }
}
