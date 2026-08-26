import { FormEvent, useEffect, useMemo, useState } from 'react';
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

export function ItemsPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [items, setItems] = useState<Item[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | 'new' | null>(null);
  const [draft, setDraft] = useState<Draft>(EMPTY_DRAFT);
  const [modifiers, setModifiers] = useState<Modifier[]>([]);
  const [modifierDraft, setModifierDraft] = useState({ name: '', priceRub: '' });

  const categoryName = useMemo(() => {
    const map = new Map(categories.map((c) => [c.id, c.name]));
    return (id: string) => map.get(id) ?? id;
  }, [categories]);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const load = () => {
    Promise.all([api.listItems(), api.listCategories()])
      .then(([itemsResult, categoriesResult]) => {
        setItems(itemsResult);
        setCategories(categoriesResult);
      })
      .catch(handleError);
  };

  useEffect(load, []);

  const startCreate = () => {
    setEditingId('new');
    setDraft({ ...EMPTY_DRAFT, categoryId: categories[0]?.id ?? '' });
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
          <h1>Блюда</h1>
        </div>
        {!editingId && (
          <button className="primary" onClick={startCreate}>
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

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Блюдо</th>
              <th>Категория</th>
              <th>Цена</th>
              <th>Наличие</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id}>
                <td>
                  <b>{item.name}</b>
                </td>
                <td>{categoryName(item.categoryId)}</td>
                <td>{item.priceRub} ₽</td>
                <td>{item.isAvailable ? <span className="status ok">в наличии</span> : <span className="status">нет</span>}</td>
                <td>
                  <a onClick={() => startEdit(item)}>Изменить</a> <a onClick={() => remove(item.id)}>Удалить</a>
                </td>
              </tr>
            ))}
            {!items.length && (
              <tr>
                <td colSpan={5}>Блюд пока нет</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
