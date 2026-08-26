import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { AdminCatalogService } from './admin-catalog.service';
import { AdminPromotionsService } from './admin-promotions.service';

export type ImportPayload = {
  categories?: Array<{ id: string; name: string; sortOrder?: number }>;
  items?: Array<{
    id: string;
    categoryId: string;
    name: string;
    description?: string;
    priceRub: number;
    isAvailable?: boolean;
    imageUrl?: string;
    weightLabel?: string;
    composition?: string;
    modifierGroupLabel?: string;
    ratingPercent?: number;
    ratingCount?: number;
    nutritionPer100g?: { caloriesKcal: number; proteinG: number; fatG: number; carbsG: number };
    modifiers?: Array<{ id: string; name: string; priceRub?: number }>;
  }>;
  promotions?: Array<{
    id: string;
    name: string;
    discountType: 'percent' | 'fixed';
    discountValue: number;
    itemId?: string;
    categoryId?: string;
    startsAt?: string;
    endsAt?: string;
    isActive?: boolean;
  }>;
};

function requireDb(database: DatabaseService): void {
  if (!database.enabled) throw new ServiceUnavailableException('Админ-панель требует настроенный DATABASE_URL.');
}

@Injectable()
export class AdminImportExportService {
  constructor(
    private readonly database: DatabaseService,
    private readonly catalog: AdminCatalogService,
    private readonly promotions: AdminPromotionsService,
  ) {}

  async exportAll() {
    const [catalog, promotions] = await Promise.all([this.catalog.exportCatalog(), this.promotions.list()]);
    return { ...catalog, promotions };
  }

  /// Upsert по id — повторный импорт того же файла ничего не задваивает,
  /// просто перезаписывает текущие значения. Модификаторы обновляются вместе
  /// со своим блюдом, но лишние (удалённые из файла) модификаторы не
  /// подчищаются — это осознанное упрощение первой версии.
  async importAll(payload: ImportPayload) {
    requireDb(this.database);
    let categories = 0;
    let items = 0;
    let modifiers = 0;
    let promotionsCount = 0;

    for (const category of payload.categories ?? []) {
      await this.database.query(
        `insert into catalog_category (id, name, sort_order) values ($1,$2,$3)
         on conflict (id) do update set name = excluded.name, sort_order = excluded.sort_order`,
        [category.id, category.name, category.sortOrder ?? 0],
      );
      categories++;
    }

    for (const item of payload.items ?? []) {
      await this.database.query(
        `insert into catalog_item
           (id, category_id, name, description, price_minor, is_available, image_url, weight_label,
            composition, calories_kcal, protein_g, fat_g, carbs_g, modifier_group_label, rating_percent, rating_count)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
         on conflict (id) do update set
           category_id = excluded.category_id, name = excluded.name, description = excluded.description,
           price_minor = excluded.price_minor, is_available = excluded.is_available, image_url = excluded.image_url,
           weight_label = excluded.weight_label, composition = excluded.composition, calories_kcal = excluded.calories_kcal,
           protein_g = excluded.protein_g, fat_g = excluded.fat_g, carbs_g = excluded.carbs_g,
           modifier_group_label = excluded.modifier_group_label, rating_percent = excluded.rating_percent,
           rating_count = excluded.rating_count`,
        [
          item.id,
          item.categoryId,
          item.name,
          item.description ?? '',
          Math.round(item.priceRub * 100),
          item.isAvailable ?? true,
          item.imageUrl ?? null,
          item.weightLabel ?? null,
          item.composition ?? null,
          item.nutritionPer100g?.caloriesKcal ?? null,
          item.nutritionPer100g?.proteinG ?? null,
          item.nutritionPer100g?.fatG ?? null,
          item.nutritionPer100g?.carbsG ?? null,
          item.modifierGroupLabel ?? null,
          item.ratingPercent ?? null,
          item.ratingCount ?? null,
        ],
      );
      items++;

      for (const modifier of item.modifiers ?? []) {
        await this.database.query(
          `insert into catalog_modifier (id, item_id, name, price_minor) values ($1,$2,$3,$4)
           on conflict (id) do update set item_id = excluded.item_id, name = excluded.name, price_minor = excluded.price_minor`,
          [modifier.id, item.id, modifier.name, Math.round((modifier.priceRub ?? 0) * 100)],
        );
        modifiers++;
      }
    }

    for (const promotion of payload.promotions ?? []) {
      await this.database.query(
        `insert into promotion (id, name, discount_type, discount_value, item_id, category_id, starts_at, ends_at, is_active)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         on conflict (id) do update set
           name = excluded.name, discount_type = excluded.discount_type, discount_value = excluded.discount_value,
           item_id = excluded.item_id, category_id = excluded.category_id, starts_at = excluded.starts_at,
           ends_at = excluded.ends_at, is_active = excluded.is_active`,
        [
          promotion.id,
          promotion.name,
          promotion.discountType,
          promotion.discountValue,
          promotion.itemId ?? null,
          promotion.categoryId ?? null,
          promotion.startsAt ?? null,
          promotion.endsAt ?? null,
          promotion.isActive ?? true,
        ],
      );
      promotionsCount++;
    }

    return { categories, items, modifiers, promotions: promotionsCount };
  }
}
