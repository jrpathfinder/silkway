import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';
import { OrdersService } from './orders.service';

class CreateOrderDto {
  locationId!: string;
  customerId!: string;
  lines!: Array<{ itemId: string; quantity: number; modifierIds?: string[] }>;
}

@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  async create(@Body() body: CreateOrderDto, @Headers('idempotency-key') key?: string) {
    return { data: await this.orders.create(body, key) };
  }

  @Post(':orderId/checkout')
  checkout(@Param('orderId') orderId: string) {
    return this.orders.createCheckout(orderId).then((payment) => ({ data: payment }));
  }

  @Get(':orderId')
  get(@Param('orderId') orderId: string) {
    return { data: this.orders.get(orderId) };
  }
}
