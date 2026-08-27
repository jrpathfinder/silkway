import { useState } from 'react';
import { getToken, setToken } from './api';
import { CategoriesPanel } from './components/CategoriesPanel';
import { ImportExportPanel } from './components/ImportExportPanel';
import { ItemsPanel } from './components/ItemsPanel';
import { LoginScreen } from './components/LoginScreen';
import { OrdersPanel } from './components/OrdersPanel';
import { PromotionsPanel } from './components/PromotionsPanel';

type Tab = 'orders' | 'items' | 'categories' | 'promotions' | 'import-export';

const TABS: { id: Tab; label: string }[] = [
  { id: 'orders', label: 'Заказы' },
  { id: 'items', label: 'Блюда' },
  { id: 'categories', label: 'Категории' },
  { id: 'promotions', label: 'Акции' },
  { id: 'import-export', label: 'Импорт / Экспорт' },
];

export function App() {
  const [authed, setAuthed] = useState(() => Boolean(getToken()));
  const [tab, setTab] = useState<Tab>('orders');

  const onUnauthorized = () => setAuthed(false);

  if (!authed) return <LoginScreen onLoggedIn={() => setAuthed(true)} />;

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          Шёлковый путь <span>АДМИН</span>
        </div>
        <nav className="tabs">
          {TABS.map((t) => (
            <button key={t.id} className={t.id === tab ? 'tab active' : 'tab'} onClick={() => setTab(t.id)}>
              {t.label}
            </button>
          ))}
        </nav>
        <button
          className="logout"
          onClick={() => {
            setToken(null);
            setAuthed(false);
          }}
        >
          Выйти
        </button>
      </header>
      <main className="content">
        {tab === 'orders' && <OrdersPanel onUnauthorized={onUnauthorized} />}
        {tab === 'items' && <ItemsPanel onUnauthorized={onUnauthorized} />}
        {tab === 'categories' && <CategoriesPanel onUnauthorized={onUnauthorized} />}
        {tab === 'promotions' && <PromotionsPanel onUnauthorized={onUnauthorized} />}
        {tab === 'import-export' && <ImportExportPanel onUnauthorized={onUnauthorized} />}
      </main>
    </div>
  );
}
