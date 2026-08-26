create extension if not exists "pgcrypto";

create table if not exists brand (
  id text primary key,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists city (
  id text primary key,
  name text not null,
  timezone text not null
);

create table if not exists restaurant_location (
  id text primary key,
  brand_id text not null references brand(id),
  city_id text not null references city(id),
  name text not null,
  address text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists catalog_category (
  id text primary key,
  name text not null,
  sort_order integer not null default 0
);

create table if not exists catalog_item (
  id text primary key,
  category_id text not null references catalog_category(id),
  name text not null,
  description text not null default '',
  price_minor integer not null check (price_minor >= 0),
  is_available boolean not null default true
);

-- schema.sql перезапускается на каждом старте (см. DatabaseService), но
-- "create table if not exists" не добавляет колонки в уже существующую
-- таблицу — поэтому новые поля идут отдельными ALTER, а не в CREATE TABLE
-- выше, иначе на любой уже поднятой базе они бы просто не появились.
alter table catalog_item add column if not exists image_url text;
alter table catalog_item add column if not exists weight_label text;
alter table catalog_item add column if not exists composition text;
alter table catalog_item add column if not exists calories_kcal numeric;
alter table catalog_item add column if not exists protein_g numeric;
alter table catalog_item add column if not exists fat_g numeric;
alter table catalog_item add column if not exists carbs_g numeric;
alter table catalog_item add column if not exists modifier_group_label text;
alter table catalog_item add column if not exists rating_percent integer;
alter table catalog_item add column if not exists rating_count integer;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'catalog_item_rating_percent_check') then
    alter table catalog_item add constraint catalog_item_rating_percent_check check (rating_percent between 0 and 100);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'catalog_item_rating_count_check') then
    alter table catalog_item add constraint catalog_item_rating_count_check check (rating_count >= 0);
  end if;
end $$;

create table if not exists catalog_modifier (
  id text primary key,
  item_id text not null references catalog_item(id),
  name text not null,
  price_minor integer not null default 0 check (price_minor >= 0)
);

-- Скидки применяются динамически при чтении каталога (CatalogService), а не
-- записываются статичной ценой в catalog_item — так цена никогда не protухнет
-- относительно активности акции.
create table if not exists promotion (
  id text primary key,
  name text not null,
  discount_type text not null check (discount_type in ('percent', 'fixed')),
  discount_value numeric not null check (discount_value > 0),
  item_id text references catalog_item(id) on delete cascade,
  category_id text references catalog_category(id) on delete cascade,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint promotion_scope_exclusive check (
    (item_id is not null and category_id is null) or (item_id is null and category_id is not null)
  )
);

insert into brand (id, name) values ('central-asia', 'Central Asia')
on conflict (id) do nothing;

insert into city (id, name, timezone) values ('moscow', 'Москва', 'Europe/Moscow')
on conflict (id) do nothing;

insert into restaurant_location (id, brand_id, city_id, name, address)
values ('ca-moscow-1', 'central-asia', 'moscow', 'Шелковый путь — Москва', 'Москва, адрес будет указан при запуске')
on conflict (id) do nothing;

insert into catalog_category (id, name, sort_order) values
  ('hot-dishes', 'Горячие блюда', 1),
  ('snacks', 'Закуски', 2)
on conflict (id) do nothing;

insert into catalog_item (id, category_id, name, description, price_minor) values
  ('plov-classic', 'hot-dishes', 'Плов классический', 'Рис, мясо, морковь и специи.', 59000),
  ('samsa-lamb', 'snacks', 'Самса с бараниной', 'Слоеное тесто и сочная начинка.', 22000)
on conflict (id) do nothing;

insert into catalog_modifier (id, item_id, name, price_minor) values
  ('extra-meat', 'plov-classic', 'Дополнительное мясо', 18000)
on conflict (id) do nothing;

create table if not exists customer (
  id text primary key,
  phone_e164 text not null unique,
  phone_verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists consent_record (
  id uuid primary key default gen_random_uuid(),
  customer_id text not null references customer(id),
  consent_type text not null,
  document_version text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz
);

create table if not exists order_header (
  id uuid primary key default gen_random_uuid(),
  location_id text not null references restaurant_location(id),
  customer_id text not null references customer(id),
  status text not null,
  currency char(3) not null default 'RUB',
  total_minor bigint not null,
  idempotency_key text unique,
  payment_provider text,
  payment_id text,
  created_at timestamptz not null default now()
);

create table if not exists order_event (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references order_header(id),
  event_type text not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists outbox_event (
  id uuid primary key default gen_random_uuid(),
  aggregate_type text not null,
  aggregate_id text not null,
  event_type text not null,
  payload jsonb not null,
  published_at timestamptz,
  created_at timestamptz not null default now()
);
