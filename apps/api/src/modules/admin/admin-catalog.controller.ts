import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Max, Min, MinLength, ValidateNested } from 'class-validator';
import { AdminAuthGuard } from './admin-auth.guard';
import { AdminCatalogService } from './admin-catalog.service';
import { AdminImportExportService, ImportPayload } from './admin-import-export.service';

class NutritionDto {
  @IsNumber() caloriesKcal!: number;
  @IsNumber() proteinG!: number;
  @IsNumber() fatG!: number;
  @IsNumber() carbsG!: number;
}

class CreateCategoryDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @MinLength(1) name!: string;
  @IsOptional() @IsInt() sortOrder?: number;
}

class UpdateCategoryDto {
  @IsOptional() @IsString() @MinLength(1) name?: string;
  @IsOptional() @IsInt() sortOrder?: number;
}

class CreateItemDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @MinLength(1) categoryId!: string;
  @IsString() @MinLength(1) name!: string;
  @IsOptional() @IsString() description?: string;
  @IsNumber() @Min(0) priceRub!: number;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
  @IsOptional() @IsString() imageUrl?: string;
  @IsOptional() @IsString() weightLabel?: string;
  @IsOptional() @IsString() composition?: string;
  @IsOptional() @IsString() modifierGroupLabel?: string;
  @IsOptional() @IsInt() @Min(0) @Max(100) ratingPercent?: number;
  @IsOptional() @IsInt() @Min(0) ratingCount?: number;
  @IsOptional() @ValidateNested() @Type(() => NutritionDto) nutritionPer100g?: NutritionDto;
}

class UpdateItemDto {
  @IsOptional() @IsString() categoryId?: string;
  @IsOptional() @IsString() @MinLength(1) name?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsNumber() @Min(0) priceRub?: number;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
  @IsOptional() @IsString() imageUrl?: string;
  @IsOptional() @IsString() weightLabel?: string;
  @IsOptional() @IsString() composition?: string;
  @IsOptional() @IsString() modifierGroupLabel?: string;
  @IsOptional() @IsInt() @Min(0) @Max(100) ratingPercent?: number;
  @IsOptional() @IsInt() @Min(0) ratingCount?: number;
  @IsOptional() @ValidateNested() @Type(() => NutritionDto) nutritionPer100g?: NutritionDto;
}

class CreateModifierDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @MinLength(1) name!: string;
  @IsOptional() @IsNumber() @Min(0) priceRub?: number;
}

class UpdateModifierDto {
  @IsOptional() @IsString() @MinLength(1) name?: string;
  @IsOptional() @IsNumber() @Min(0) priceRub?: number;
}

class ImportDto {
  @IsOptional() categories?: ImportPayload['categories'];
  @IsOptional() items?: ImportPayload['items'];
  @IsOptional() promotions?: ImportPayload['promotions'];
}

@UseGuards(AdminAuthGuard)
@Controller('admin/catalog')
export class AdminCatalogController {
  constructor(
    private readonly service: AdminCatalogService,
    private readonly importExport: AdminImportExportService,
  ) {}

  @Get('export')
  async export() {
    return { data: await this.importExport.exportAll() };
  }

  @Post('import')
  async import(@Body() body: ImportDto) {
    return { data: await this.importExport.importAll(body) };
  }

  @Get('categories')
  async listCategories() {
    return { data: await this.service.listCategories() };
  }

  @Post('categories')
  async createCategory(@Body() body: CreateCategoryDto) {
    return { data: await this.service.createCategory(body) };
  }

  @Patch('categories/:id')
  async updateCategory(@Param('id') id: string, @Body() body: UpdateCategoryDto) {
    await this.service.updateCategory(id, body);
    return { data: { ok: true } };
  }

  @Delete('categories/:id')
  async deleteCategory(@Param('id') id: string) {
    await this.service.deleteCategory(id);
    return { data: { ok: true } };
  }

  @Get('items')
  async listItems(@Query('categoryId') categoryId?: string) {
    return { data: await this.service.listItems(categoryId) };
  }

  @Post('items')
  async createItem(@Body() body: CreateItemDto) {
    return { data: await this.service.createItem(body) };
  }

  @Patch('items/:id')
  async updateItem(@Param('id') id: string, @Body() body: UpdateItemDto) {
    return { data: await this.service.updateItem(id, body) };
  }

  @Delete('items/:id')
  async deleteItem(@Param('id') id: string) {
    await this.service.deleteItem(id);
    return { data: { ok: true } };
  }

  @Get('items/:itemId/modifiers')
  async listModifiers(@Param('itemId') itemId: string) {
    return { data: await this.service.listModifiers(itemId) };
  }

  @Post('items/:itemId/modifiers')
  async createModifier(@Param('itemId') itemId: string, @Body() body: CreateModifierDto) {
    return { data: await this.service.createModifier(itemId, body) };
  }

  @Patch('modifiers/:id')
  async updateModifier(@Param('id') id: string, @Body() body: UpdateModifierDto) {
    await this.service.updateModifier(id, body);
    return { data: { ok: true } };
  }

  @Delete('modifiers/:id')
  async deleteModifier(@Param('id') id: string) {
    await this.service.deleteModifier(id);
    return { data: { ok: true } };
  }
}
