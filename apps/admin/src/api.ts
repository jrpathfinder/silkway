import type { Category, CatalogExport, Item, Modifier, Promotion } from './types';

const BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 'http://localhost:3000/v1';
const TOKEN_STORAGE_KEY = 'sw-admin-token';

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_STORAGE_KEY);
}

export function setToken(token: string | null): void {
  if (token) localStorage.setItem(TOKEN_STORAGE_KEY, token);
  else localStorage.removeItem(TOKEN_STORAGE_KEY);
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { 'Content-Type': 'application/json', ...(options.headers as Record<string, string>) };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  if (res.status === 401) {
    setToken(null);
    throw new ApiError(401, 'Сессия истекла — войдите заново');
  }
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(res.status, body.message ?? `Ошибка ${res.status}`);
  return body.data as T;
}

export const api = {
  login: (password: string) => request<{ token: string; expiresAt: string }>('/admin/auth/login', { method: 'POST', body: JSON.stringify({ password }) }),

  listCategories: () => request<Category[]>('/admin/catalog/categories'),
  createCategory: (input: { id?: string; name: string; sortOrder?: number }) =>
    request<Category>('/admin/catalog/categories', { method: 'POST', body: JSON.stringify(input) }),
  updateCategory: (id: string, input: { name?: string; sortOrder?: number }) =>
    request<{ ok: true }>(`/admin/catalog/categories/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  deleteCategory: (id: string) => request<{ ok: true }>(`/admin/catalog/categories/${encodeURIComponent(id)}`, { method: 'DELETE' }),

  listItems: (categoryId?: string) => request<Item[]>(`/admin/catalog/items${categoryId ? `?categoryId=${encodeURIComponent(categoryId)}` : ''}`),
  createItem: (input: Partial<Item> & { categoryId: string; name: string; priceRub: number }) =>
    request<Item>('/admin/catalog/items', { method: 'POST', body: JSON.stringify(input) }),
  updateItem: (id: string, input: Partial<Item>) =>
    request<Item>(`/admin/catalog/items/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  deleteItem: (id: string) => request<{ ok: true }>(`/admin/catalog/items/${encodeURIComponent(id)}`, { method: 'DELETE' }),

  listModifiers: (itemId: string) => request<Modifier[]>(`/admin/catalog/items/${encodeURIComponent(itemId)}/modifiers`),
  createModifier: (itemId: string, input: { id?: string; name: string; priceRub?: number }) =>
    request<Modifier>(`/admin/catalog/items/${encodeURIComponent(itemId)}/modifiers`, { method: 'POST', body: JSON.stringify(input) }),
  updateModifier: (id: string, input: { name?: string; priceRub?: number }) =>
    request<{ ok: true }>(`/admin/catalog/modifiers/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  deleteModifier: (id: string) => request<{ ok: true }>(`/admin/catalog/modifiers/${encodeURIComponent(id)}`, { method: 'DELETE' }),

  listPromotions: () => request<Promotion[]>('/admin/promotions'),
  createPromotion: (input: Partial<Promotion> & { name: string; discountType: 'percent' | 'fixed'; discountValue: number }) =>
    request<Promotion>('/admin/promotions', { method: 'POST', body: JSON.stringify(input) }),
  updatePromotion: (id: string, input: Partial<Promotion>) =>
    request<Promotion>(`/admin/promotions/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  deletePromotion: (id: string) => request<{ ok: true }>(`/admin/promotions/${encodeURIComponent(id)}`, { method: 'DELETE' }),

  exportCatalog: () => request<CatalogExport>('/admin/catalog/export'),
  importCatalog: (payload: Partial<CatalogExport>) =>
    request<{ categories: number; items: number; modifiers: number; promotions: number }>('/admin/catalog/import', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
};
