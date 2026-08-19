type Order = { id: string; customer: string; total: string; status: string; createdAt: string };

const orders: Order[] = [
  { id: '#CA-1001', customer: '+7 999 *** 12 34', total: '1 180 ₽', status: 'Ожидает оплаты', createdAt: 'сегодня, 12:45' },
  { id: '#CA-1000', customer: '+7 916 *** 45 67', total: '760 ₽', status: 'Готовится', createdAt: 'сегодня, 12:39' },
];

const root = document.querySelector<HTMLDivElement>('#app');
if (!root) throw new Error('Admin root not found');

root.innerHTML = `
  <main class="shell">
    <header class="topbar"><div class="brand">Central Asia <span>ADMIN</span></div><div class="user">Оператор · Москва</div></header>
    <section class="content">
      <div class="heading"><div><p class="eyebrow">СРЕДА, 13 АВГУСТА</p><h1>Добрый день</h1></div><button class="primary">+ Добавить блюдо</button></div>
      <div class="stats"><div><small>Заказы сегодня</small><strong>24</strong><em>+12% к вчера</em></div><div><small>Выручка</small><strong>38 420 ₽</strong><em>+8% к вчера</em></div><div><small>Среднее время</small><strong>42 мин</strong><em>−5 мин к вчера</em></div></div>
      <div class="panel"><div class="panel-title"><h2>Последние заказы</h2><a href="#">Все заказы →</a></div><table><thead><tr><th>Заказ</th><th>Клиент</th><th>Сумма</th><th>Статус</th><th>Время</th></tr></thead><tbody>${orders.map((order) => `<tr><td><b>${order.id}</b></td><td>${order.customer}</td><td>${order.total}</td><td><span class="status">${order.status}</span></td><td>${order.createdAt}</td></tr>`).join('')}</tbody></table></div>
      <div class="quick"><h2>Быстрые действия</h2><button>Каталог и наличие</button><button>Зоны доставки</button><button>Настройки точки</button></div>
    </section>
  </main>`;
