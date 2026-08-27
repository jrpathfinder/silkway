import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';
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

  @Get(':orderId')
  get(@Param('orderId') orderId: string) {
    return { data: this.orders.get(orderId) };
  }
}
