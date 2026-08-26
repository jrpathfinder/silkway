import { ConflictException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';

export type AdminPromotionInput = {
  id?: string;
  name: string;
  discountType: 'percent' | 'fixed';
  discountValue: number;
  itemId?: string;
  categoryId?: string;
  startsAt?: string;
  endsAt?: string;
  isActive?: boolean;
};

function requireDb(database: DatabaseService): void {
  if (!database.enabled) throw new ServiceUnavailableException('Админ-панель требует настроенный DATABASE_URL.');
}

function slugify(input: string): string {
  const slug = input
    .toLowerCase()
    .replace(/[^a-z0-9а-яё]+/gi, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 64);
  return slug || 'promo';
}

function mapRow(row: Record<string, unknown>) {
  return {
    id: row.id as string,
    name: row.name as string,
    discountType: row.discount_type as 'percent' | 'fixed',
    discountValue: Number(row.discount_value),
    itemId: (row.item_id as string) ?? undefined,
    categoryId: (row.category_id as string) ?? undefined,
    startsAt: (row.starts_at as Date | null)?.toISOString() ?? undefined,
    endsAt: (row.ends_at as Date | null)?.toISOString() ?? undefined,
    isActive: row.is_active as boolean,
  };
}

@Injectable()
export class AdminPromotionsService {
  constructor(private readonly database: DatabaseService) {}

  async list() {
    requireDb(this.database);
    const { rows } = await this.database.query(
      `select id, name, discount_type, discount_value, item_id, category_id, starts_at, ends_at, is_active
       from promotion order by created_at desc`,
    );
    return rows.map(mapRow);
  }

  async create(input: AdminPromotionInput) {
    requireDb(this.database);
    const id = input.id?.trim() || slugify(input.name);
    const existing = await this.database.query(`select id from promotion where id = $1`, [id]);
    if (existing.rowCount) throw new ConflictException(`Акция с id "${id}" уже существует`);
    const { rows } = await this.database.query(
      `insert into promotion (id, name, discount_type, discount_value, item_id, category_id, starts_at, ends_at, is_active)
       values ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       returning *`,
      [
        id,
        input.name,
        input.discountType,
        input.discountValue,
        input.itemId ?? null,
        input.categoryId ?? null,
        input.startsAt ?? null,
        input.endsAt ?? null,
        input.isActive ?? true,
      ],
    );
    return mapRow(rows[0]);
  }

  async update(id: string, input: Partial<AdminPromotionInput>) {
    requireDb(this.database);
    const { rows } = await this.database.query(
      `update promotion set
         name = coalesce($2, name),
         discount_type = coalesce($3, discount_type),
         discount_value = coalesce($4, discount_value),
         starts_at = coalesce($5, starts_at),
         ends_at = coalesce($6, ends_at),
         is_active = coalesce($7, is_active)
       where id = $1
       returning *`,
      [id, input.name ?? null, input.discountType ?? null, input.discountValue ?? null, input.startsAt ?? null, input.endsAt ?? null, input.isActive ?? null],
    );
    if (!rows.length) throw new NotFoundException(`Акция "${id}" не найдена`);
    return mapRow(rows[0]);
  }

  async delete(id: string) {
    requireDb(this.database);
    const { rowCount } = await this.database.query(`delete from promotion where id = $1`, [id]);
    if (!rowCount) throw new NotFoundException(`Акция "${id}" не найдена`);
  }
}
