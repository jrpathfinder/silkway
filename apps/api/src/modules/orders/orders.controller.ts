import { BadRequestException, Body, Controller, Get, Headers, Param, Post, Query } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsArray, IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min, MinLength, ValidateNested } from 'class-validator';
import { OrdersService } from './orders.service';

class DeliveryAddressDto {
  @IsNumber() lat!: number;
  @IsNumber() lng!: number;
  @IsString() @MinLength(1) addressText!: string;
  @IsOptional() @IsString() comment?: string;
}

class CreateOrderLineDto {
  @IsString() itemId!: string;
  @IsInt() @Min(1) @Max(20) quantity!: number;
  @IsOptional() @IsArray() @IsString({ each: true }) modifierIds?: string[];
}

class CreateOrderDto {
  @IsString() locationId!: string;
  @IsString() customerId!: string;
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderLineDto)
  lines!: CreateOrderLineDto[];
  @IsOptional() @IsIn(['DELIVERY', 'PICKUP']) fulfillmentType?: 'DELIVERY' | 'PICKUP';
  @IsOptional() @ValidateNested() @Type(() => DeliveryAddressDto) deliveryAddress?: DeliveryAddressDto;
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

  /// Ручной путь к оплате для мок-провайдера — единственный способ
  /// подтвердить оплату без реального вебхука (см. OrdersService.markPaidForDemo
  /// и, для ЮKassa, PaymentWebhookController).
  @Post(':orderId/mark-paid-demo')
  async markPaidDemo(@Param('orderId') orderId: string) {
    return { data: await this.orders.markPaidForDemo(orderId) };
  }

  @Get(':orderId')
  async get(@Param('orderId') orderId: string) {
    return { data: await this.orders.get(orderId) };
  }

  /// «Мои заказы» в клиенте — ранее не было маршрута вовсе (см.
  /// OrdersRepositoryHttp.listForCustomer), экран всегда падал с
  /// UnimplementedError.
  @Get()
  async listForCustomer(@Query('customerId') customerId?: string) {
    if (!customerId) throw new BadRequestException('customerId is required');
    return { data: await this.orders.listForCustomer(customerId) };
  }
}
