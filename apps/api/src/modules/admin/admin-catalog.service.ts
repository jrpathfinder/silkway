import { ConflictException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

export type AdminNutrition = { caloriesKcal: number; proteinG: number; fatG: number; carbsG: number };

export type AdminModifierInput = { id?: string; name: string; priceRub?: number };

export type AdminItemInput = {
  id?: string;
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
  nutritionPer100g?: AdminNutrition;
};

function requireDb(database: DatabaseService): void {
  if (!database.enabled) throw new ServiceUnavailableException('Админ-панель требует настроенный DATABASE_URL.');
}

/// Латиница и кириллица допускаются в id — витринные названия часто русские,
/// а отдельная транслитерация не стоит сложности для внутреннего идентификатора.
function slugify(input: string): string {
  const slug = input
    .toLowerCase()
    .replace(/[^a-z0-9а-яё]+/gi, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 64);
  return slug || 'item';
}

/// Внешний ключ без ON DELETE CASCADE — удаление категории/блюда с
/// зависимыми строками падает кодом 23503. Превращаем это в понятное
/// сообщение вместо голой ошибки Postgres.
async function runOrConflict(promise: Promise<unknown>, message: string): Promise<void> {
  try {
    await promise;
  } catch (error: unknown) {
    if ((error as { code?: string })?.code === '23503') throw new ConflictException(message);
    throw error;
  }
}

function mapItemRow(row: Record<string, unknown>) {
  const hasNutrition =
    row.calories_kcal != null && row.protein_g != null && row.fat_g != null && row.carbs_g != null;
  return {
    id: row.id as string,
    categoryId: row.category_id as string,
    name: row.name as string,
    description: row.description as string,
    priceRub: Number(row.price_minor) / 100,
    isAvailable: row.is_available as boolean,
    imageUrl: (row.image_url as string) ?? undefined,
    weightLabel: (row.weight_label as string) ?? undefined,
    composition: (row.composition as string) ?? undefined,
    modifierGroupLabel: (row.modifier_group_label as string) ?? undefined,
    ratingPercent: (row.rating_percent as number) ?? undefined,
    ratingCount: (row.rating_count as number) ?? undefined,
    nutritionPer100g: hasNutrition
      ? {
          caloriesKcal: Number(row.calories_kcal),
          proteinG: Number(row.protein_g),
          fatG: Number(row.fat_g),
          carbsG: Number(row.carbs_g),
        }
      : undefined,
  };
}

function mapModifierRow(row: Record<string, unknown>) {
  return { id: row.id as string, itemId: row.item_id as string, name: row.name as string, priceRub: Number(row.price_minor) / 100 };
}

@Injectable()
export class AdminCatalogService {
  constructor(private readonly database: DatabaseService) {}

  async listCategories() {
    requireDb(this.database);
    const { rows } = await this.database.query<{ id: string; name: string; sort_order: number }>(
      `select id, name, sort_order from catalog_category order by sort_order, name`,
    );
    return rows.map((r) => ({ id: r.id, name: r.name, sortOrder: r.sort_order }));
  }

  async createCategory(input: { id?: string; name: string; sortOrder?: number }) {
    requireDb(this.database);
    const id = input.id?.trim() || slugify(input.name);
    const existing = await this.database.query(`select id from catalog_category where id = $1`, [id]);
    if (existing.rowCount) throw new ConflictException(`Категория с id "${id}" уже существует`);
    await this.database.query(`insert into catalog_category (id, name, sort_order) values ($1, $2, $3)`, [
      id,
      input.name,
      input.sortOrder ?? 0,
    ]);
    return { id, name: input.name, sortOrder: input.sortOrder ?? 0 };
  }

  async updateCategory(id: string, input: { name?: string; sortOrder?: number }) {
    requireDb(this.database);
    const { rowCount } = await this.database.query(
      `update catalog_category set name = coalesce($2, name), sort_order = coalesce($3, sort_order) where id = $1`,
      [id, input.name ?? null, input.sortOrder ?? null],
    );
    if (!rowCount) throw new NotFoundException(`Категория "${id}" не найдена`);
  }

  async deleteCategory(id: string) {
    requireDb(this.database);
    await runOrConflict(
      this.database.query(`delete from catalog_category where id = $1`, [id]).then((r) => {
        if (!r.rowCount) throw new NotFoundException(`Категория "${id}" не найдена`);
      }),
      `Нельзя удалить категорию "${id}": в ней ещё есть блюда`,
    );
  }

  async listItems(categoryId?: string) {
    requireDb(this.database);
    const { rows } = await this.database.query(
      categoryId ? `select * from catalog_item where category_id = $1 order by name` : `select * from catalog_item order by category_id, name`,
      categoryId ? [categoryId] : [],
    );
    return rows.map(mapItemRow);
  }

  async createItem(input: AdminItemInput) {
    requireDb(this.database);
    const id = input.id?.trim() || slugify(input.name);
    const existing = await this.database.query(`select id from catalog_item where id = $1`, [id]);
    if (existing.rowCount) throw new ConflictException(`Блюдо с id "${id}" уже существует`);
    const { rows } = await this.database.query(
      `insert into catalog_item
        (id, category_id, name, description, price_minor, is_available, image_url, weight_label,
         composition, calories_kcal, protein_g, fat_g, carbs_g, modifier_group_label, rating_percent, rating_count)
       values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
       returning *`,
      [
        id,
        input.categoryId,
        input.name,
        input.description ?? '',
        Math.round(input.priceRub * 100),
        input.isAvailable ?? true,
        input.imageUrl ?? null,
        input.weightLabel ?? null,
        input.composition ?? null,
        input.nutritionPer100g?.caloriesKcal ?? null,
        input.nutritionPer100g?.proteinG ?? null,
        input.nutritionPer100g?.fatG ?? null,
        input.nutritionPer100g?.carbsG ?? null,
        input.modifierGroupLabel ?? null,
        input.ratingPercent ?? null,
        input.ratingCount ?? null,
      ],
    );
    return mapItemRow(rows[0]);
  }

  async updateItem(id: string, input: Partial<AdminItemInput>) {
    requireDb(this.database);
    const priceMinor = input.priceRub != null ? Math.round(input.priceRub * 100) : null;
    const { rows } = await this.database.query(
      `update catalog_item set
         category_id = coalesce($2, category_id),
         name = coalesce($3, name),
         description = coalesce($4, description),
         price_minor = coalesce($5, price_minor),
         is_available = coalesce($6, is_available),
         image_url = coalesce($7, image_url),
         weight_label = coalesce($8, weight_label),
         composition = coalesce($9, composition),
         calories_kcal = coalesce($10, calories_kcal),
         protein_g = coalesce($11, protein_g),
         fat_g = coalesce($12, fat_g),
         carbs_g = coalesce($13, carbs_g),
         modifier_group_label = coalesce($14, modifier_group_label),
         rating_percent = coalesce($15, rating_percent),
         rating_count = coalesce($16, rating_count)
       where id = $1
       returning *`,
      [
        id,
        input.categoryId ?? null,
        input.name ?? null,
        input.description ?? null,
        priceMinor,
        input.isAvailable ?? null,
        input.imageUrl ?? null,
        input.weightLabel ?? null,
        input.composition ?? null,
        input.nutritionPer100g?.caloriesKcal ?? null,
        input.nutritionPer100g?.proteinG ?? null,
        input.nutritionPer100g?.fatG ?? null,
        input.nutritionPer100g?.carbsG ?? null,
        input.modifierGroupLabel ?? null,
        input.ratingPercent ?? null,
        input.ratingCount ?? null,
      ],
    );
    if (!rows.length) throw new NotFoundException(`Блюдо "${id}" не найдено`);
    return mapItemRow(rows[0]);
  }

  async deleteItem(id: string) {
    requireDb(this.database);
    await runOrConflict(
      this.database.query(`delete from catalog_item where id = $1`, [id]).then((r) => {
        if (!r.rowCount) throw new NotFoundException(`Блюдо "${id}" не найдено`);
      }),
      `Нельзя удалить блюдо "${id}": сначала удалите его модификаторы`,
    );
  }

  async listModifiers(itemId: string) {
    requireDb(this.database);
    const { rows } = await this.database.query(
      `select id, item_id, name, price_minor from catalog_modifier where item_id = $1 order by name`,
      [itemId],
    );
    return rows.map(mapModifierRow);
  }

  async createModifier(itemId: string, input: AdminModifierInput) {
    requireDb(this.database);
    const id = input.id?.trim() || slugify(`${itemId}-${input.name}`);
    const existing = await this.database.query(`select id from catalog_modifier where id = $1`, [id]);
    if (existing.rowCount) throw new ConflictException(`Модификатор с id "${id}" уже существует`);
    await this.database.query(`insert into catalog_modifier (id, item_id, name, price_minor) values ($1,$2,$3,$4)`, [
      id,
      itemId,
      input.name,
      Math.round((input.priceRub ?? 0) * 100),
    ]);
    return { id, itemId, name: input.name, priceRub: input.priceRub ?? 0 };
  }

  async updateModifier(id: string, input: { name?: string; priceRub?: number }) {
    requireDb(this.database);
    const priceMinor = input.priceRub != null ? Math.round(input.priceRub * 100) : null;
    const { rowCount } = await this.database.query(
      `update catalog_modifier set name = coalesce($2, name), price_minor = coalesce($3, price_minor) where id = $1`,
      [id, input.name ?? null, priceMinor],
    );
    if (!rowCount) throw new NotFoundException(`Модификатор "${id}" не найден`);
  }

  async deleteModifier(id: string) {
    requireDb(this.database);
    const { rowCount } = await this.database.query(`delete from catalog_modifier where id = $1`, [id]);
    if (!rowCount) throw new NotFoundException(`Модификатор "${id}" не найден`);
  }

  /// Полный слепок каталога для экспорта — «сырые» авторские цены и данные,
  /// БЕЗ применения скидок (это делает CatalogService.getForLocation
  /// отдельно, на чтении витрины). Повторный импорт этого же слепка не
  /// должен задваивать скидку.
  async exportCatalog() {
    requireDb(this.database);
    const [categories, items, modifiers] = await Promise.all([
      this.database.query(`select id, name, sort_order from catalog_category order by sort_order, name`),
      this.database.query(`select * from catalog_item order by category_id, name`),
      this.database.query(`select id, item_id, name, price_minor from catalog_modifier order by item_id, name`),
    ]);
    return {
      categories: categories.rows.map((r: any) => ({ id: r.id, name: r.name, sortOrder: r.sort_order })),
      items: items.rows.map((item: any) => ({
        ...mapItemRow(item),
        modifiers: modifiers.rows.filter((m: any) => m.item_id === item.id).map(mapModifierRow).map(({ itemId: _itemId, ...rest }) => rest),
      })),
    };
  }
}
