#!/usr/bin/env node
// Шаг 2 из двух (см. tools/import-yandex-menu.mjs): маппинг сырого меню
// Яндекс.Еда в формат, который принимает POST /v1/admin/catalog/import.
//
// Комбо (data.combos) сюда намеренно не идут: это конструктор "выбери суп +
// второе", у него нет собственной цены/состава — в модели каталога такого
// понятия нет, а не выдумываем несуществующую фичу.
//
//   node tools/map-yandex-menu.mjs [путь к yandex-menu.json]
//
// Пишет tools/out/catalog-import-payload.json — для просмотра перед
// реальным импортом, ничего никуда не отправляет.

import { readFile, writeFile } from 'node:fs/promises';

const inPath = process.argv[2] ?? 'tools/out/yandex-menu.json';
const raw = JSON.parse(await readFile(inPath, 'utf8'));

const UNIT_LABEL = { kg: 'кг', g: 'г', l: 'л', ml: 'мл' };

function weightLabel(weight) {
  if (!weight?.value) return undefined;
  const unit = UNIT_LABEL[weight.unit] ?? weight.unit;
  return `${weight.value} ${unit}`;
}

function composition(item) {
  const ingredients = item.additional_descriptions?.ingredients;
  if (ingredients?.length) return ingredients.join(', ');
  return item.additional_descriptions?.artistic_info || undefined;
}

// Только категории, на которые реально ссылается хотя бы один обычный item
// (не комбо) — иначе осталась бы пустая категория "Комбо".
const usedCategoryIds = new Set(raw.items.map((item) => item.categories_ids[0].id));

const categories = raw.categories
  .filter((c) => usedCategoryIds.has(c.id))
  .map((c) => ({ id: c.id, name: c.name, sortOrder: c.sort }));

const items = raw.items.map((item) => ({
  id: item.id,
  categoryId: item.categories_ids[0].id,
  name: item.name,
  description: item.description || undefined,
  priceRub: Number(item.price),
  isAvailable: item.available === true && item.stopped !== true,
  imageUrl: item.pictures?.[0],
  weightLabel: weightLabel(item.weight),
  composition: composition(item),
}));

const payload = { categories, items };
await writeFile('tools/out/catalog-import-payload.json', JSON.stringify(payload, null, 2));

console.error(
  `Категорий: ${categories.length} (из ${raw.categories.length} исходных, остальные пусты после исключения комбо).`,
);
console.error(`Блюд: ${items.length}. Пропущено комбо: ${raw.combos.length}.`);
console.error('Записано в tools/out/catalog-import-payload.json — просмотрите перед импортом.');
