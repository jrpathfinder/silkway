import { useEffect, useRef, useState } from 'react';
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

// Статус красится одним из трёх фирменных цветов по смыслу, а не по
// статусу самому по себе: красный — ждёт действия ресторана прямо сейчас,
// золото — ждёт кого-то другого (оплаты, курьера), синий — уже не в руках
// ресторана, серый — финальное состояние.
function statusPillClass(status: OrderStatus): string {
  switch (status) {
    case 'PAID':
    case 'ACCEPTED':
    case 'PREPARING':
      return 'status-pill action';
    case 'PENDING_PAYMENT':
    case 'READY_FOR_DELIVERY':
      return 'status-pill wait';
    case 'IN_DELIVERY':
    case 'DELIVERED':
      return 'status-pill transit';
    default:
      return 'status-pill neutral';
  }
}

function formatRub(value: number): string {
  return `${value.toLocaleString('ru-RU')} ₽`;
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
}

function shortId(id: string): string {
  return `№…${id.slice(-6)}`;
}

/// Звуковой сигнал, пока есть хоть один оплаченный, но не принятый заказ —
/// не один раз, а повторяется, чтобы не потерялось, если никто не смотрит на
/// экран в момент оплаты. Останавливается сам, как только все приняты.
/// Короткий двухтональный «пинг» в духе мессенджеров конца 90-х — не
/// сэмпл (реальный звук ICQ — чужой авторский актив, который нельзя
/// встраивать в продукт), а собственный синтез той же идеи: две короткие
/// восходящие ноты чистым тоном. Второй тон чуть громче и длиннее первого —
/// на этом держится узнаваемость всей категории таких сигналов.
function pingNotification(ctx: AudioContext, destination: AudioNode) {
  const now = ctx.currentTime;
  const master = ctx.createGain();
  master.gain.value = 0.5;
  master.connect(destination);

  const notes: Array<[frequencyHz: number, startOffset: number, duration: number, level: number]> = [
    [659, 0, 0.11, 0.35], // E5
    [988, 0.1, 0.16, 0.45], // B5
  ];
  for (const [frequencyHz, startOffset, duration, level] of notes) {
    const start = now + startOffset;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = frequencyHz;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(level, start + 0.012);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    osc.connect(gain).connect(master);
    osc.start(start);
    osc.stop(start + duration + 0.02);
  }
}

function useUnacceptedAlertSound(hasUnaccepted: boolean) {
  useEffect(() => {
    if (!hasUnaccepted) return;

    let ctx: AudioContext;
    try {
      ctx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
    } catch {
      return;
    }

    const ping = () => {
      if (ctx.state === 'suspended') ctx.resume().catch(() => {});
      pingNotification(ctx, ctx.destination);
    };

    ping();
    const interval = setInterval(ping, 4000);
    return () => {
      clearInterval(interval);
      ctx.close().catch(() => {});
    };
  }, [hasUnaccepted]);
}

export function OrdersPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [showAll, setShowAll] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selectedIdRef = useRef<string | null>(null);
  selectedIdRef.current = selectedId;

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const load = () => {
    api
      .listOrders(showAll ? undefined : ACTIVE_STATUSES)
      .then((data) => {
        const sorted = [...data].sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
        setOrders(sorted);
        setError(null);
        // Держим выбранный заказ, если он всё ещё в списке; иначе — первый.
        const current = selectedIdRef.current;
        if (!current || !sorted.some((o) => o.id === current)) {
          setSelectedId(sorted[0]?.id ?? null);
        }
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

  const unacceptedCount = orders.filter((o) => o.status === 'PAID').length;
  useUnacceptedAlertSound(unacceptedCount > 0);

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

  const selected = orders.find((o) => o.id === selectedId) ?? null;

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

      {unacceptedCount > 0 && (
        <div className="alert-banner">
          🔔 {unacceptedCount} {unacceptedCount === 1 ? 'заказ ждёт' : 'заказа ждут'} подтверждения
        </div>
      )}

      <div className="orders-board">
        <div className="order-list">
          {orders.map((order) => (
            <button
              key={order.id}
              className={`order-card${order.id === selectedId ? ' selected' : ''}${order.status === 'PAID' ? ' needs-action' : ''}`}
              onClick={() => setSelectedId(order.id)}
            >
              <div className="order-card-top">
                <span className="order-card-id">{shortId(order.id)}</span>
                <span className="order-card-sum">{formatRub(order.totalRub)}</span>
              </div>
              <div className="order-card-meta">
                <span className="muted">
                  {order.lines.length} {order.lines.length === 1 ? 'блюдо' : 'блюда'} · {formatTime(order.createdAt)}
                </span>
                <span className={statusPillClass(order.status)}>{STATUS_LABEL[order.status]}</span>
              </div>
            </button>
          ))}
          {!orders.length && (
            <div className="muted" style={{ padding: 16 }}>
              {showAll ? 'Заказов пока нет' : 'Активных заказов нет'}
            </div>
          )}
        </div>

        <div className="panel order-detail">
          {!selected ? (
            <div className="order-detail-section muted">Выберите заказ слева</div>
          ) : (
            <>
              <div className="order-detail-header">
                <div>
                  <p className="order-detail-id">{shortId(selected.id)}</p>
                  <div className="pill-row">
                    <span className={statusPillClass(selected.status)}>{STATUS_LABEL[selected.status]}</span>
                    <span className="status-pill neutral">{selected.fulfillmentType === 'DELIVERY' ? 'Доставка' : 'Самовывоз'}</span>
                  </div>
                  <span className="muted">Создан {formatTime(selected.createdAt)}</span>
                </div>
                {NEXT_ACTION[selected.status] && (
                  <button className="primary" disabled={busyId === selected.id} onClick={() => runAction(selected)}>
                    {busyId === selected.id ? '…' : NEXT_ACTION[selected.status]!.label}
                  </button>
                )}
              </div>

              {(selected.deliveryAddress?.addressText || selected.deliveryAddress?.comment) && (
                <div className="order-detail-section">
                  {selected.deliveryAddress?.addressText && (
                    <div className="order-detail-row">
                      <span className="label">Адрес</span>
                      <span>{selected.deliveryAddress.addressText}</span>
                    </div>
                  )}
                  {selected.deliveryAddress?.comment && (
                    <div className="order-detail-row">
                      <span className="label">Комментарий</span>
                      <span>{selected.deliveryAddress.comment}</span>
                    </div>
                  )}
                </div>
              )}

              <div className="order-detail-section">
                {selected.lines.map((line, i) => (
                  <div className="order-line" key={i}>
                    <span className="qty">{line.quantity}×</span>
                    <span className="name">{line.name}</span>
                    <span>{formatRub(line.unitPriceRub * line.quantity)}</span>
                  </div>
                ))}
                <div className="order-total-row">
                  <span>Итого</span>
                  <span>{formatRub(selected.totalRub)}</span>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </section>
  );
}
