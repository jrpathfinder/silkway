import { ChangeEvent, FormEvent, useEffect, useMemo, useState } from 'react';
import { api, ApiError } from '../api';
import type { Category, Item, Modifier } from '../types';

type Draft = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  priceRub: string;
  isAvailable: boolean;
  imageUrl: string;
  weightLabel: string;
  composition: string;
  modifierGroupLabel: string;
  ratingPercent: string;
  ratingCount: string;
  caloriesKcal: string;
  proteinG: string;
  fatG: string;
  carbsG: string;
};

const EMPTY_DRAFT: Draft = {
  id: '',
  categoryId: '',
  name: '',
  description: '',
  priceRub: '',
  isAvailable: true,
  imageUrl: '',
  weightLabel: '',
  composition: '',
  modifierGroupLabel: '',
  ratingPercent: '',
  ratingCount: '',
  caloriesKcal: '',
  proteinG: '',
  fatG: '',
  carbsG: '',
};

function itemToDraft(item: Item): Draft {
  return {
    id: item.id,
    categoryId: item.categoryId,
    name: item.name,
    description: item.description,
    priceRub: String(item.priceRub),
    isAvailable: item.isAvailable,
    imageUrl: item.imageUrl ?? '',
    weightLabel: item.weightLabel ?? '',
    composition: item.composition ?? '',
    modifierGroupLabel: item.modifierGroupLabel ?? '',
    ratingPercent: item.ratingPercent != null ? String(item.ratingPercent) : '',
    ratingCount: item.ratingCount != null ? String(item.ratingCount) : '',
    caloriesKcal: item.nutritionPer100g ? String(item.nutritionPer100g.caloriesKcal) : '',
    proteinG: item.nutritionPer100g ? String(item.nutritionPer100g.proteinG) : '',
    fatG: item.nutritionPer100g ? String(item.nutritionPer100g.fatG) : '',
    carbsG: item.nutritionPer100g ? String(item.nutritionPer100g.carbsG) : '',
  };
}

function draftToPayload(draft: Draft) {
  const hasNutrition = draft.caloriesKcal || draft.proteinG || draft.fatG || draft.carbsG;
  return {
    id: draft.id || undefined,
    categoryId: draft.categoryId,
    name: draft.name,
    description: draft.description || undefined,
    priceRub: Number(draft.priceRub),
    isAvailable: draft.isAvailable,
    imageUrl: draft.imageUrl || undefined,
    weightLabel: draft.weightLabel || undefined,
    composition: draft.composition || undefined,
    modifierGroupLabel: draft.modifierGroupLabel || undefined,
    ratingPercent: draft.ratingPercent ? Number(draft.ratingPercent) : undefined,
    ratingCount: draft.ratingCount ? Number(draft.ratingCount) : undefined,
    nutritionPer100g: hasNutrition
      ? {
          caloriesKcal: Number(draft.caloriesKcal || 0),
          proteinG: Number(draft.proteinG || 0),
          fatG: Number(draft.fatG || 0),
          carbsG: Number(draft.carbsG || 0),
        }
      : undefined,
  };
}

function formatRub(value: number): string {
  return `${value.toLocaleString('ru-RU')} ₽`;
}

export function MenuPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [items, setItems] = useState<Item[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | 'new' | null>(null);
  const [draft, setDraft] = useState<Draft>(EMPTY_DRAFT);
  const [modifiers, setModifiers] = useState<Modifier[]>([]);
  const [modifierDraft, setModifierDraft] = useState({ name: '', priceRub: '' });
  const [uploading, setUploading] = useState(false);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const load = () => {
    Promise.all([api.listItems(), api.listCategories()])
      .then(([itemsResult, categoriesResult]) => {
        setItems(itemsResult);
        setCategories(categoriesResult);
        setSelectedCategoryId((current) => current ?? categoriesResult[0]?.id ?? null);
      })
      .catch(handleError);
  };

  useEffect(load, []);

  const itemCountByCategory = useMemo(() => {
    const counts = new Map<string, number>();
    for (const item of items) counts.set(item.categoryId, (counts.get(item.categoryId) ?? 0) + 1);
    return counts;
  }, [items]);

  const itemsInSelectedCategory = useMemo(
    () => items.filter((item) => item.categoryId === selectedCategoryId),
    [items, selectedCategoryId],
  );

  const selectedCategory = categories.find((c) => c.id === selectedCategoryId) ?? null;

  const addCategory = async () => {
    const name = prompt('Название новой категории');
    if (!name) return;
    try {
      const created = await api.createCategory({ name });
      await Promise.resolve(load());
      setSelectedCategoryId(created.id);
    } catch (err) {
      handleError(err);
    }
  };

  const renameCategory = async (category: Category) => {
    const name = prompt('Новое название категории', category.name);
    if (!name || name === category.name) return;
    try {
      await api.updateCategory(category.id, { name });
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const removeCategory = async (category: Category) => {
    if (!confirm(`Удалить категорию «${category.name}»? Блюда в ней нужно перенести заранее.`)) return;
    try {
      await api.deleteCategory(category.id);
      if (selectedCategoryId === category.id) setSelectedCategoryId(null);
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const toggleAvailability = async (item: Item) => {
    try {
      await api.updateItem(item.id, { isAvailable: !item.isAvailable });
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const startCreate = () => {
    setEditingId('new');
    setDraft({ ...EMPTY_DRAFT, categoryId: selectedCategoryId ?? categories[0]?.id ?? '' });
    setModifiers([]);
  };

  const startEdit = (item: Item) => {
    setEditingId(item.id);
    setDraft(itemToDraft(item));
    api.listModifiers(item.id).then(setModifiers).catch(handleError);
  };

  const cancelEdit = () => {
    setEditingId(null);
    setDraft(EMPTY_DRAFT);
    setModifiers([]);
  };

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      if (editingId === 'new') {
        await api.createItem(draftToPayload(draft));
      } else if (editingId) {
        await api.updateItem(editingId, draftToPayload(draft));
      }
      cancelEdit();
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const remove = async (id: string) => {
    if (!confirm(`Удалить блюдо "${id}"?`)) return;
    try {
      await api.deleteItem(id);
      if (editingId === id) cancelEdit();
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const uploadImage = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = ''; // let picking the same file again re-trigger onChange
    if (!file) return;
    setUploading(true);
    setError(null);
    try {
      const { url } = await api.uploadImage(file);
      setDraft((d) => ({ ...d, imageUrl: url }));
    } catch (err) {
      handleError(err);
    } finally {
      setUploading(false);
    }
  };

  const addModifier = async (e: FormEvent) => {
    e.preventDefault();
    if (editingId === 'new' || !editingId) return;
    try {
      await api.createModifier(editingId, { name: modifierDraft.name, priceRub: modifierDraft.priceRub ? Number(modifierDraft.priceRub) : undefined });
      setModifierDraft({ name: '', priceRub: '' });
      const list = await api.listModifiers(editingId);
      setModifiers(list);
    } catch (err) {
      handleError(err);
    }
  };

  const removeModifier = async (id: string) => {
    if (editingId === 'new' || !editingId) return;
    try {
      await api.deleteModifier(id);
      const list = await api.listModifiers(editingId);
      setModifiers(list);
    } catch (err) {
      handleError(err);
    }
  };

  return (
    <section>
      <div className="heading">
        <div>
          <p className="eyebrow">Каталог</p>
          <h1>Меню</h1>
        </div>
        {!editingId && (
          <button className="primary" onClick={startCreate} disabled={!categories.length}>
            + Добавить блюдо
          </button>
        )}
      </div>

      {error && <div className="form-error">{error}</div>}

      {editingId && (
        <form className="panel form-panel" onSubmit={save}>
          <div className="panel-title">
            <h2>{editingId === 'new' ? 'Новое блюдо' : `Блюдо: ${draft.name}`}</h2>
            <a onClick={cancelEdit}>Отмена</a>
          </div>
          <div className="form-grid">
            {editingId === 'new' && (
              <label>
                ID (необязательно)
                <input value={draft.id} onChange={(e) => setDraft({ ...draft, id: e.target.value })} placeholder="сгенерируется из названия" />
              </label>
            )}
            <label>
              Категория
              <select value={draft.categoryId} onChange={(e) => setDraft({ ...draft, categoryId: e.target.value })} required>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Название
              <input value={draft.name} onChange={(e) => setDraft({ ...draft, name: e.target.value })} required />
            </label>
            <label>
              Цена, ₽
              <input type="number" step="0.01" value={draft.priceRub} onChange={(e) => setDraft({ ...draft, priceRub: e.target.value })} required />
            </label>
            <label>
              Вес/объём
              <input value={draft.weightLabel} onChange={(e) => setDraft({ ...draft, weightLabel: e.target.value })} placeholder="300 г" />
            </label>
            <label>
              Фото (URL)
              <input value={draft.imageUrl} onChange={(e) => setDraft({ ...draft, imageUrl: e.target.value })} />
            </label>
            <label>
              Загрузить фото со своего компьютера
              <input type="file" accept="image/jpeg,image/png,image/webp" onChange={uploadImage} disabled={uploading} />
            </label>
            {uploading && <span className="muted">Загрузка…</span>}
            {draft.imageUrl && !uploading && <img src={draft.imageUrl} alt="" className="image-preview" />}
            <label className="span-2">
              Описание
              <textarea value={draft.description} onChange={(e) => setDraft({ ...draft, description: e.target.value })} rows={2} />
            </label>
            <label className="span-2">
              Состав
              <textarea value={draft.composition} onChange={(e) => setDraft({ ...draft, composition: e.target.value })} rows={2} />
            </label>
            <label>
              Рейтинг, %
              <input type="number" min={0} max={100} value={draft.ratingPercent} onChange={(e) => setDraft({ ...draft, ratingPercent: e.target.value })} />
            </label>
            <label>
              Число оценок
              <input type="number" min={0} value={draft.ratingCount} onChange={(e) => setDraft({ ...draft, ratingCount: e.target.value })} />
            </label>
            <label className="span-2">
              Заголовок группы модификаторов
              <input value={draft.modifierGroupLabel} onChange={(e) => setDraft({ ...draft, modifierGroupLabel: e.target.value })} placeholder="К плову" />
            </label>
            <fieldset className="span-2">
              <legend>БЖУ на 100 г</legend>
              <div className="nutrition-grid">
                <input type="number" placeholder="ккал" value={draft.caloriesKcal} onChange={(e) => setDraft({ ...draft, caloriesKcal: e.target.value })} />
                <input type="number" placeholder="белки" value={draft.proteinG} onChange={(e) => setDraft({ ...draft, proteinG: e.target.value })} />
                <input type="number" placeholder="жиры" value={draft.fatG} onChange={(e) => setDraft({ ...draft, fatG: e.target.value })} />
                <input type="number" placeholder="углеводы" value={draft.carbsG} onChange={(e) => setDraft({ ...draft, carbsG: e.target.value })} />
              </div>
            </fieldset>
            <label className="checkbox-label">
              <input type="checkbox" checked={draft.isAvailable} onChange={(e) => setDraft({ ...draft, isAvailable: e.target.checked })} />
              В наличии
            </label>
          </div>

          {editingId !== 'new' && (
            <div className="modifiers-block">
              <h2>Модификаторы</h2>
              <ul className="modifier-list">
                {modifiers.map((m) => (
                  <li key={m.id}>
                    {m.name} <span>+{m.priceRub} ₽</span>
                    <a onClick={() => removeModifier(m.id)}>Удалить</a>
                  </li>
                ))}
                {!modifiers.length && <li className="muted">Пока нет модификаторов</li>}
              </ul>
              <div className="inline-form">
                <input
                  placeholder="Название модификатора"
                  value={modifierDraft.name}
                  onChange={(e) => setModifierDraft({ ...modifierDraft, name: e.target.value })}
                />
                <input
                  placeholder="Доплата, ₽"
                  type="number"
                  value={modifierDraft.priceRub}
                  onChange={(e) => setModifierDraft({ ...modifierDraft, priceRub: e.target.value })}
                  style={{ width: 120 }}
                />
                <button type="button" onClick={addModifier}>
                  Добавить
                </button>
              </div>
            </div>
          )}

          <button className="primary" type="submit">
            Сохранить
          </button>
        </form>
      )}

      {!editingId && (
        <div className="menu-board">
          <div className="menu-sidebar">
            <div className="menu-sidebar-title">
              <h2>Категории · {categories.length}</h2>
              <button className="icon-button" onClick={addCategory} title="Добавить категорию">
                +
              </button>
            </div>
            <div className="category-list">
              {categories.map((c) => (
                <button
                  key={c.id}
                  className={`category-row${c.id === selectedCategoryId ? ' selected' : ''}`}
                  onClick={() => setSelectedCategoryId(c.id)}
                >
                  <span>{c.name}</span>
                  <span className="count">{itemCountByCategory.get(c.id) ?? 0}</span>
                </button>
              ))}
              {!categories.length && <p className="muted">Категорий пока нет</p>}
            </div>
          </div>

          <div className="panel menu-content">
            {selectedCategory ? (
              <>
                <div className="menu-content-header">
                  <div>
                    <h2>{selectedCategory.name}</h2>
                    <span className="muted">{itemsInSelectedCategory.length} позиций</span>
                  </div>
                  <div className="inline-form" style={{ marginBottom: 0 }}>
                    <a onClick={() => renameCategory(selectedCategory)}>Переименовать</a>
                    <a onClick={() => removeCategory(selectedCategory)}>Удалить категорию</a>
                  </div>
                </div>
                {itemsInSelectedCategory.map((item) => (
                  <div className={`item-row${item.isAvailable ? '' : ' item-row-unavailable'}`} key={item.id}>
                    <label className="sw-toggle" title={item.isAvailable ? 'В наличии' : 'Нет в наличии'}>
                      <input type="checkbox" checked={item.isAvailable} onChange={() => toggleAvailability(item)} />
                      <span className="track" />
                    </label>
                    {item.imageUrl ? <img src={item.imageUrl} alt="" className="item-thumb" /> : <div className="item-thumb" />}
                    <div className="item-row-name">
                      <b>{item.name}</b>
                      {item.weightLabel && <span className="muted weight">{item.weightLabel}</span>}
                    </div>
                    <div className="item-row-price">{formatRub(item.priceRub)}</div>
                    <a onClick={() => startEdit(item)}>Изменить</a>
                    <a onClick={() => remove(item.id)}>Удалить</a>
                  </div>
                ))}
                {!itemsInSelectedCategory.length && (
                  <div className="order-detail-section muted">В этой категории пока нет блюд</div>
                )}
              </>
            ) : (
              <div className="order-detail-section muted">Выберите категорию слева или создайте новую</div>
            )}
          </div>
        </div>
      )}
    </section>
  );
}
