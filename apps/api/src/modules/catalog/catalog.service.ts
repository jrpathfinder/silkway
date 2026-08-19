import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

export type CatalogItem = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  priceRub: number;
  isAvailable: boolean;
  modifiers: Array<{ id: string; name: string; priceRub: number }>;
};

type CategoryRow = { id: string; name: string; sort_order: number };
type ItemRow = {
  id: string;
  category_id: string;
  name: string;
  description: string;
  price_minor: number;
  is_available: boolean;
};
type ModifierRow = { id: string; item_id: string; name: string; price_minor: number };

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

    const [categories, items, modifiers] = await Promise.all([
      this.database.query<CategoryRow>(
        `select id, name, sort_order from catalog_category order by sort_order, name`,
      ),
      this.database.query<ItemRow>(
        `select ci.id, ci.category_id, ci.name, ci.description, ci.price_minor, ci.is_available
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
    ]);

    return {
      locationId,
      currency: 'RUB',
      categories: categories.rows,
      items: items.rows.map((item) => ({
        id: item.id,
        categoryId: item.category_id,
        name: item.name,
        description: item.description,
        priceRub: Number(item.price_minor) / 100,
        isAvailable: item.is_available,
        modifiers: modifiers.rows
          .filter((modifier) => modifier.item_id === item.id)
          .map((modifier) => ({ id: modifier.id, name: modifier.name, priceRub: Number(modifier.price_minor) / 100 })),
      })),
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
