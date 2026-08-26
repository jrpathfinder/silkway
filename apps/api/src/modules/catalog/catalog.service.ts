import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

export type CatalogNutritionFacts = {
  caloriesKcal: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
};

export type CatalogItem = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  priceRub: number;
  isAvailable: boolean;
  modifiers: Array<{ id: string; name: string; priceRub: number }>;
  imageUrl?: string;
  weightLabel?: string;
  originalPriceRub?: number;
  ratingPercent?: number;
  ratingCount?: number;
  composition?: string;
  nutritionPer100g?: CatalogNutritionFacts;
  modifierGroupLabel?: string;
};

type CategoryRow = { id: string; name: string; sort_order: number };
type ItemRow = {
  id: string;
  category_id: string;
  name: string;
  description: string;
  price_minor: number;
  is_available: boolean;
  image_url: string | null;
  weight_label: string | null;
  composition: string | null;
  calories_kcal: string | null;
  protein_g: string | null;
  fat_g: string | null;
  carbs_g: string | null;
  modifier_group_label: string | null;
  rating_percent: number | null;
  rating_count: number | null;
};
type ModifierRow = { id: string; item_id: string; name: string; price_minor: number };
type PromotionRow = {
  id: string;
  discount_type: 'percent' | 'fixed';
  discount_value: string;
  item_id: string | null;
  category_id: string | null;
};

const fallbackCatalog: CatalogItem[] = [
  {
    id: 'plov-classic',
    categoryId: 'hot-dishes',
    name: 'Плов классический',
    description: 'Рис, мясо, морковь и специи.',
    priceRub: 590,
    isAvailable: true,
    modifiers: [{ id: 'extra-meat', name: 'Дополнительное мясо', priceRub: 180 }],
  },
  {
    id: 'samsa-lamb',
    categoryId: 'snacks',
    name: 'Самса с бараниной',
    description: 'Слоеное тесто и сочная начинка.',
    priceRub: 220,
    isAvailable: true,
    modifiers: [],
  },
];

@Injectable()
export class CatalogService {
  constructor(private readonly database: DatabaseService) {}

  async getForLocation(locationId: string) {
    if (!this.database.enabled) return this.fromFallback(locationId);

    const [categories, items, modifiers, promotions] = await Promise.all([
      this.database.query<CategoryRow>(
        `select id, name, sort_order from catalog_category order by sort_order, name`,
      ),
      this.database.query<ItemRow>(
        `select ci.id, ci.category_id, ci.name, ci.description, ci.price_minor, ci.is_available,
                ci.image_url, ci.weight_label, ci.composition, ci.calories_kcal, ci.protein_g,
                ci.fat_g, ci.carbs_g, ci.modifier_group_label, ci.rating_percent, ci.rating_count
         from catalog_item ci
         join restaurant_location rl on rl.id = $1
         where ci.is_available = true and rl.is_active = true`,
        [locationId],
      ),
      this.database.query<ModifierRow>(
        `select cm.id, cm.item_id, cm.name, cm.price_minor
         from catalog_modifier cm
         join catalog_item ci on ci.id = cm.item_id
         join restaurant_location rl on rl.id = $1
         where ci.is_available = true and rl.is_active = true`,
        [locationId],
      ),
      this.database.query<PromotionRow>(
        `select id, discount_type, discount_value, item_id, category_id
         from promotion
         where is_active = true
           and (starts_at is null or starts_at <= now())
           and (ends_at is null or ends_at >= now())`,
      ),
    ]);

    return {
      locationId,
      currency: 'RUB',
      categories: categories.rows,
      items: items.rows.map((item) => {
        const priceMinor = item.price_minor;
        const discountedMinor = this.applyBestPromotion(priceMinor, item.id, item.category_id, promotions.rows);
        const nutritionPer100g = this.mapNutrition(item);
        return {
          id: item.id,
          categoryId: item.category_id,
          name: item.name,
          description: item.description,
          priceRub: discountedMinor / 100,
          isAvailable: item.is_available,
          modifiers: modifiers.rows
            .filter((modifier) => modifier.item_id === item.id)
            .map((modifier) => ({ id: modifier.id, name: modifier.name, priceRub: Number(modifier.price_minor) / 100 })),
          imageUrl: item.image_url ?? undefined,
          weightLabel: item.weight_label ?? undefined,
          originalPriceRub: discountedMinor < priceMinor ? priceMinor / 100 : undefined,
          ratingPercent: item.rating_percent ?? undefined,
          ratingCount: item.rating_count ?? undefined,
          composition: item.composition ?? undefined,
          nutritionPer100g,
          modifierGroupLabel: item.modifier_group_label ?? undefined,
        };
      }),
    };
  }

  /// Скидки — не хранимая цена, а вычисляются при каждом чтении каталога:
  /// если акцию выключат/она истечёт, цена в тот же момент вернётся к
  /// базовой без отдельного шага "снять скидку" на данных.
  ///
  /// Когда позиции соответствует и товарная, и категорийная акция — берём
  /// ту, что даёт покупателю бОльшую скидку, а не первую попавшуюся.
  private applyBestPromotion(
    baseMinor: number,
    itemId: string,
    categoryId: string,
    promotions: PromotionRow[],
  ): number {
    const matching = promotions.filter((p) => p.item_id === itemId || p.category_id === categoryId);
    if (!matching.length) return baseMinor;

    const candidates = matching.map((promotion) => {
      const value = Number(promotion.discount_value);
      const discounted =
        promotion.discount_type === 'percent' ? baseMinor * (1 - value / 100) : baseMinor - value;
      return Math.max(0, Math.round(discounted));
    });
    return Math.min(baseMinor, ...candidates);
  }

  private mapNutrition(item: ItemRow): CatalogNutritionFacts | undefined {
    if (
      item.calories_kcal == null ||
      item.protein_g == null ||
      item.fat_g == null ||
      item.carbs_g == null
    ) {
      return undefined;
    }
    return {
      caloriesKcal: Number(item.calories_kcal),
      proteinG: Number(item.protein_g),
      fatG: Number(item.fat_g),
      carbsG: Number(item.carbs_g),
    };
  }

  private fromFallback(locationId: string) {
    return {
      locationId,
      currency: 'RUB',
      categories: [
        { id: 'hot-dishes', name: 'Горячие блюда', sort_order: 1 },
        { id: 'snacks', name: 'Закуски', sort_order: 2 },
      ],
      items: fallbackCatalog.filter((item) => item.isAvailable),
    };
  }
}
