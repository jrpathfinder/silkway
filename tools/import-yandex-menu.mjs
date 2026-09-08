#!/usr/bin/env node
// Выгрузка меню из Яндекс.Еда Vendor API.
//
// Шаг 1 из двух: скрипт только СКАЧИВАЕТ и сохраняет сырой ответ. Маппинг в
// наши модели пишется уже по реальным данным — угадывать форму ответа по
// документации значит закладывать ошибки, которые всплывут на проде.
//
// Токен читается из окружения и никуда не логируется. В репозиторий он
// попасть не должен: .env уже в .gitignore.
//
//   export YANDEX_EDA_TOKEN=...          # личный кабинет -> Интеграция
//   export YANDEX_EDA_RESTAURANT_ID=...  # id ресторана в системе партнёра
//   export YANDEX_EDA_BASE_URL=...       # хост API, если отличается
//   node tools/import-yandex-menu.mjs

import { writeFile, mkdir } from 'node:fs/promises';

const token = process.env.YANDEX_EDA_TOKEN;
const restaurantId = process.env.YANDEX_EDA_RESTAURANT_ID;
const baseUrl = process.env.YANDEX_EDA_BASE_URL ?? 'https://eda-integration.yandex.ru/vendor/v1';

const missing = [
  !token && 'YANDEX_EDA_TOKEN',
  !restaurantId && 'YANDEX_EDA_RESTAURANT_ID',
].filter(Boolean);

if (missing.length) {
  console.error(`Не заданы переменные окружения: ${missing.join(', ')}`);
  console.error('Токен берётся в личном кабинете Яндекс.Еда, раздел «Интеграция».');
  process.exit(1);
}

const url = `${baseUrl.replace(/\/$/, '')}/menu/${encodeURIComponent(restaurantId)}/composition`;
console.error(`GET ${url}`);

let res;
try {
  res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.eats.menu.composition.v2+json, application/json',
    },
  });
} catch (err) {
  console.error(`Не удалось соединиться: ${err.message}`);
  console.error('Проверьте YANDEX_EDA_BASE_URL — хост этого метода в документации не указан явно.');
  process.exit(1);
}

const body = await res.text();

if (!res.ok) {
  console.error(`HTTP ${res.status} ${res.statusText}`);
  // 401 — самая частая причина: токен протух или скопирован не полностью.
  if (res.status === 401) console.error('Токен не принят: истёк или указан неверно.');
  if (res.status === 404) console.error('Не найдено: проверьте restaurantId и базовый URL.');
  console.error(body.slice(0, 500));
  process.exit(1);
}

await mkdir('tools/out', { recursive: true });
const out = 'tools/out/yandex-menu.json';
await writeFile(out, body);

// Короткая сводка, чтобы сразу видеть, что выгрузилось.
try {
  const data = JSON.parse(body);
  const n = (x) => (Array.isArray(x) ? x.length : 0);
  console.error(
    `Сохранено в ${out}: категорий ${n(data.categories)}, позиций ${n(data.items)}, комбо ${n(data.combos)}.`,
  );
  if (data.lastChange) console.error(`Меню изменялось: ${data.lastChange}`);
} catch {
  console.error(`Сохранено в ${out} (${body.length} байт), но это не JSON — посмотрите содержимое.`);
}
