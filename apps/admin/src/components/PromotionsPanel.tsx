import { FormEvent, useEffect, useState } from 'react';
import { api, ApiError } from '../api';
import type { Category, Item, Promotion } from '../types';

type ScopeKind = 'item' | 'category';

type Draft = {
  name: string;
  discountType: 'percent' | 'fixed';
  discountValue: string;
  scopeKind: ScopeKind;
  scopeId: string;
  startsAt: string;
  endsAt: string;
};

const EMPTY_DRAFT: Draft = {
  name: '',
  discountType: 'percent',
  discountValue: '',
  scopeKind: 'item',
  scopeId: '',
  startsAt: '',
  endsAt: '',
};

export function PromotionsPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [draft, setDraft] = useState<Draft>(EMPTY_DRAFT);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const load = () => {
    Promise.all([api.listPromotions(), api.listItems(), api.listCategories()])
      .then(([p, i, c]) => {
        setPromotions(p);
        setItems(i);
        setCategories(c);
      })
      .catch(handleError);
  };

  useEffect(load, []);

  const scopeLabel = (p: Promotion) => {
    if (p.itemId) return `Блюдо: ${items.find((i) => i.id === p.itemId)?.name ?? p.itemId}`;
    if (p.categoryId) return `Категория: ${categories.find((c) => c.id === p.categoryId)?.name ?? p.categoryId}`;
    return '—';
  };

  const create = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      await api.createPromotion({
        name: draft.name,
        discountType: draft.discountType,
        discountValue: Number(draft.discountValue),
        itemId: draft.scopeKind === 'item' ? draft.scopeId : undefined,
        categoryId: draft.scopeKind === 'category' ? draft.scopeId : undefined,
        startsAt: draft.startsAt ? new Date(draft.startsAt).toISOString() : undefined,
        endsAt: draft.endsAt ? new Date(draft.endsAt).toISOString() : undefined,
      });
      setShowForm(false);
      setDraft(EMPTY_DRAFT);
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const toggleActive = async (p: Promotion) => {
    try {
      await api.updatePromotion(p.id, { isActive: !p.isActive });
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const remove = async (id: string) => {
    if (!confirm(`Удалить акцию "${id}"?`)) return;
    try {
      await api.deletePromotion(id);
      load();
    } catch (err) {
      handleError(err);
    }
  };

  return (
    <section>
      <div className="heading">
        <div>
          <p className="eyebrow">Каталог</p>
          <h1>Акции</h1>
        </div>
        {!showForm && (
          <button className="primary" onClick={() => setShowForm(true)}>
            + Новая акция
          </button>
        )}
      </div>

      {error && <div className="form-error">{error}</div>}

      {showForm && (
        <form className="panel form-panel" onSubmit={create}>
          <div className="panel-title">
            <h2>Новая акция</h2>
            <a onClick={() => setShowForm(false)}>Отмена</a>
          </div>
          <div className="form-grid">
            <label>
              Название
              <input value={draft.name} onChange={(e) => setDraft({ ...draft, name: e.target.value })} required />
            </label>
            <label>
              Тип скидки
              <select value={draft.discountType} onChange={(e) => setDraft({ ...draft, discountType: e.target.value as 'percent' | 'fixed' })}>
                <option value="percent">Процент</option>
                <option value="fixed">Фиксированная сумма, ₽</option>
              </select>
            </label>
            <label>
              Значение {draft.discountType === 'percent' ? '(%)' : '(₽)'}
              <input type="number" step="0.01" value={draft.discountValue} onChange={(e) => setDraft({ ...draft, discountValue: e.target.value })} required />
            </label>
            <label>
              Применяется к
              <select value={draft.scopeKind} onChange={(e) => setDraft({ ...draft, scopeKind: e.target.value as ScopeKind, scopeId: '' })}>
                <option value="item">Одному блюду</option>
                <option value="category">Категории</option>
              </select>
            </label>
            <label>
              {draft.scopeKind === 'item' ? 'Блюдо' : 'Категория'}
              <select value={draft.scopeId} onChange={(e) => setDraft({ ...draft, scopeId: e.target.value })} required>
                <option value="" disabled>
                  Выберите…
                </option>
                {(draft.scopeKind === 'item' ? items : categories).map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Начало (необязательно)
              <input type="datetime-local" value={draft.startsAt} onChange={(e) => setDraft({ ...draft, startsAt: e.target.value })} />
            </label>
            <label>
              Окончание (необязательно)
              <input type="datetime-local" value={draft.endsAt} onChange={(e) => setDraft({ ...draft, endsAt: e.target.value })} />
            </label>
          </div>
          <button className="primary" type="submit">
            Создать
          </button>
        </form>
      )}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Акция</th>
              <th>Скидка</th>
              <th>Действует на</th>
              <th>Статус</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {promotions.map((p) => (
              <tr key={p.id}>
                <td>
                  <b>{p.name}</b>
                </td>
                <td>{p.discountType === 'percent' ? `${p.discountValue}%` : `${p.discountValue} ₽`}</td>
                <td>{scopeLabel(p)}</td>
                <td>
                  <span className={p.isActive ? 'status ok' : 'status'}>{p.isActive ? 'активна' : 'выключена'}</span>
                </td>
                <td>
                  <a onClick={() => toggleActive(p)}>{p.isActive ? 'Выключить' : 'Включить'}</a> <a onClick={() => remove(p.id)}>Удалить</a>
                </td>
              </tr>
            ))}
            {!promotions.length && (
              <tr>
                <td colSpan={5}>Акций пока нет</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
