import { FormEvent, useEffect, useState } from 'react';
import { api, ApiError } from '../api';
import type { Category } from '../types';

export function CategoriesPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [sortOrder, setSortOrder] = useState('');

  const load = () =>
    api
      .listCategories()
      .then(setCategories)
      .catch((err) => handleError(err));

  useEffect(() => {
    load();
  }, []);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const create = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      await api.createCategory({ name, sortOrder: sortOrder ? Number(sortOrder) : undefined });
      setName('');
      setSortOrder('');
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const remove = async (id: string) => {
    if (!confirm(`Удалить категорию "${id}"?`)) return;
    try {
      await api.deleteCategory(id);
      load();
    } catch (err) {
      handleError(err);
    }
  };

  const renameSortOrder = async (category: Category, sortOrderValue: string) => {
    const value = Number(sortOrderValue);
    if (Number.isNaN(value)) return;
    try {
      await api.updateCategory(category.id, { sortOrder: value });
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
          <h1>Категории</h1>
        </div>
      </div>

      {error && <div className="form-error">{error}</div>}

      <form className="inline-form" onSubmit={create}>
        <input placeholder="Название категории" value={name} onChange={(e) => setName(e.target.value)} required />
        <input
          placeholder="Порядок"
          type="number"
          value={sortOrder}
          onChange={(e) => setSortOrder(e.target.value)}
          style={{ width: 100 }}
        />
        <button className="primary" type="submit">
          Добавить
        </button>
      </form>

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Название</th>
              <th>Порядок</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {categories.map((c) => (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>
                  <b>{c.name}</b>
                </td>
                <td>
                  <input
                    type="number"
                    defaultValue={c.sortOrder}
                    className="cell-input"
                    onBlur={(e) => renameSortOrder(c, e.target.value)}
                  />
                </td>
                <td>
                  <a onClick={() => remove(c.id)}>Удалить</a>
                </td>
              </tr>
            ))}
            {!categories.length && (
              <tr>
                <td colSpan={4}>Категорий пока нет</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
