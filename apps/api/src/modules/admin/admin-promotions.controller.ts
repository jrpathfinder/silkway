import { BadRequestException, Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IsBoolean, IsIn, IsISO8601, IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';
import { AdminAuthGuard } from './admin-auth.guard';
import { AdminPromotionsService } from './admin-promotions.service';

class CreatePromotionDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @MinLength(1) name!: string;
  @IsIn(['percent', 'fixed']) discountType!: 'percent' | 'fixed';
  @IsNumber() @Min(0.01) discountValue!: number;
  @IsOptional() @IsString() itemId?: string;
  @IsOptional() @IsString() categoryId?: string;
  @IsOptional() @IsISO8601() startsAt?: string;
  @IsOptional() @IsISO8601() endsAt?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

class UpdatePromotionDto {
  @IsOptional() @IsString() @MinLength(1) name?: string;
  @IsOptional() @IsIn(['percent', 'fixed']) discountType?: 'percent' | 'fixed';
  @IsOptional() @IsNumber() @Min(0.01) discountValue?: number;
  @IsOptional() @IsISO8601() startsAt?: string;
  @IsOptional() @IsISO8601() endsAt?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

@UseGuards(AdminAuthGuard)
@Controller('admin/promotions')
export class AdminPromotionsController {
  constructor(private readonly service: AdminPromotionsService) {}

  @Get()
  async list() {
    return { data: await this.service.list() };
  }

  @Post()
  async create(@Body() body: CreatePromotionDto) {
    if (Boolean(body.itemId) === Boolean(body.categoryId)) {
      throw new BadRequestException('Укажите ровно одно: itemId или categoryId');
    }
    return { data: await this.service.create(body) };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: UpdatePromotionDto) {
    return { data: await this.service.update(id, body) };
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    await this.service.delete(id);
    return { data: { ok: true } };
  }
}
