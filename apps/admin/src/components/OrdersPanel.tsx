import { useEffect, useState } from 'react';
import { api, ApiError } from '../api';
import type { Order, OrderStatus } from '../types';

const ACTIVE_STATUSES: OrderStatus[] = ['PAID', 'ACCEPTED', 'PREPARING', 'READY_FOR_DELIVERY', 'IN_DELIVERY'];

const STATUS_LABEL: Record<OrderStatus, string> = {
  PENDING_PAYMENT: 'Ожидает оплаты',
  PAID: 'Оплачен',
  ACCEPTED: 'Принят',
  PREPARING: 'Готовится',
  READY_FOR_DELIVERY: 'Готов к выдаче',
  IN_DELIVERY: 'В пути',
  DELIVERED: 'Доставлен',
  CANCELLED: 'Отменён',
  REFUNDED: 'Возврат',
};

// Действие ресторана для текущего статуса — если действия нет (ждём курьера
// или заказ уже завершён), кнопки не показываем.
const NEXT_ACTION: Partial<Record<OrderStatus, { label: string; run: (id: string) => Promise<Order> }>> = {
  PAID: { label: 'Принять', run: api.acceptOrder },
  ACCEPTED: { label: 'Начать готовить', run: api.prepareOrder },
  PREPARING: { label: 'Готово к выдаче', run: api.readyOrder },
};

function statusClassName(status: OrderStatus): string {
  return status === 'DELIVERED' ? 'status ok' : 'status';
}

function formatRub(value: number): string {
  return `${value.toLocaleString('ru-RU')} ₽`;
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
}

export function OrdersPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [showAll, setShowAll] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const load = () => {
    api
      .listOrders(showAll ? undefined : ACTIVE_STATUSES)
      .then((data) => {
        setOrders([...data].sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)));
        setError(null);
      })
      .catch(handleError);
  };

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(load, [showAll]);

  // Новые оплаченные заказы должны появляться сами — панель без этого
  // пришлось бы держать открытой и постоянно жать «Обновить».
  useEffect(() => {
    const interval = setInterval(load, 5000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [showAll]);

  const runAction = async (order: Order) => {
    const action = NEXT_ACTION[order.status];
    if (!action) return;
    setBusyId(order.id);
    try {
      await action.run(order.id);
      load();
    } catch (err) {
      handleError(err);
    } finally {
      setBusyId(null);
    }
  };

  return (
    <section>
      <div className="heading">
        <div>
          <p className="eyebrow">Ресторан</p>
          <h1>Заказы</h1>
        </div>
        <div className="inline-form" style={{ marginBottom: 0 }}>
          <button className={showAll ? 'tab' : 'tab active'} onClick={() => setShowAll(false)}>
            Активные
          </button>
          <button className={showAll ? 'tab active' : 'tab'} onClick={() => setShowAll(true)}>
            Все
          </button>
          <button onClick={load}>Обновить</button>
        </div>
      </div>

      {error && <div className="form-error">{error}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Заказ</th>
              <th>Состав</th>
              <th>Сумма</th>
              <th>Получение</th>
              <th>Статус</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => {
              const action = NEXT_ACTION[order.status];
              return (
                <tr key={order.id}>
                  <td>
                    <b>#{order.id.slice(0, 8)}</b>
                    <div className="muted">{formatTime(order.createdAt)}</div>
                  </td>
                  <td>{order.lines.map((line) => `${line.quantity}× ${line.name}`).join(', ')}</td>
                  <td>{formatRub(order.totalRub)}</td>
                  <td>{order.fulfillmentType === 'DELIVERY' ? 'Доставка' : 'Самовывоз'}</td>
                  <td>
                    <span className={statusClassName(order.status)}>{STATUS_LABEL[order.status]}</span>
                  </td>
                  <td>
                    {action ? (
                      <a
                        onClick={() => (busyId === order.id ? undefined : runAction(order))}
                        style={{ opacity: busyId === order.id ? 0.5 : 1 }}
                      >
                        {action.label}
                      </a>
                    ) : (
                      <span className="muted">—</span>
                    )}
                  </td>
                </tr>
              );
            })}
            {!orders.length && (
              <tr>
                <td colSpan={6}>{showAll ? 'Заказов пока нет' : 'Активных заказов нет'}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
