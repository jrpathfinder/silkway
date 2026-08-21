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

create table if not exists catalog_modifier (
  id text primary key,
  item_id text not null references catalog_item(id),
  name text not null,
  price_minor integer not null default 0 check (price_minor >= 0)
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
