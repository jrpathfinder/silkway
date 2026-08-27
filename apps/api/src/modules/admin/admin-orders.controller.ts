import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { OrderStatus } from '../orders/order.types';
import { OrdersService } from '../orders/orders.service';
import { AdminAuthGuard } from './admin-auth.guard';

const ALL_STATUSES: OrderStatus[] = [
  'PENDING_PAYMENT',
  'PAID',
  'ACCEPTED',
  'PREPARING',
  'READY_FOR_DELIVERY',
  'IN_DELIVERY',
  'DELIVERED',
  'CANCELLED',
  'REFUNDED',
];

function parseStatuses(raw?: string): OrderStatus[] | undefined {
  if (!raw) return undefined;
  const requested = raw.split(',').map((s) => s.trim().toUpperCase());
  return requested.filter((s): s is OrderStatus => (ALL_STATUSES as string[]).includes(s));
}

@UseGuards(AdminAuthGuard)
@Controller('admin/orders')
export class AdminOrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  list(@Query('status') status?: string) {
    return { data: this.orders.listByStatuses(parseStatuses(status)) };
  }

  @Post(':id/accept')
  accept(@Param('id') id: string) {
    return { data: this.orders.accept(id) };
  }

  @Post(':id/prepare')
  prepare(@Param('id') id: string) {
    return { data: this.orders.startPreparing(id) };
  }

  @Post(':id/ready')
  ready(@Param('id') id: string) {
    return { data: this.orders.markReadyForDelivery(id) };
  }
}
