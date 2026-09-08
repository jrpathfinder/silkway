import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_skeleton.dart';
import '../../../core/models/order.dart';
import '../../../core/utils/money.dart';
import 'providers/orders_providers.dart';

/// Статус заказа: где он сейчас, из чего состоит и сколько стоит.
///
/// Прогресс показан вертикальным таймлайном по реальным значениям
/// [OrderStatus] — раньше это был один Chip, по которому нельзя было понять,
/// что уже позади, а что впереди.
///
/// Карты и позиции курьера здесь нет намеренно: `CourierRepository` — пустая
/// заглушка, и рисовать движение курьера означало бы выдумать данные.
class OrderStatusScreen extends ConsumerStatefulWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  /// Обычный путь заказа. Отмена и возврат сюда не входят: это не этапы, а
  /// выход из процесса, и показываются отдельно.
  static const _flow = [
    OrderStatus.pendingPayment,
    OrderStatus.paid,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.readyForDelivery,
    OrderStatus.inDelivery,
    OrderStatus.delivered,
  ];

  static const _terminal = {OrderStatus.delivered, OrderStatus.cancelled, OrderStatus.refunded};

  static String label(OrderStatus status) => switch (status) {
        OrderStatus.pendingPayment => 'Ожидает оплаты',
        OrderStatus.paid => 'Оплачен',
        OrderStatus.accepted => 'Принят рестораном',
        OrderStatus.preparing => 'Готовится',
        OrderStatus.readyForDelivery => 'Готов к доставке',
        OrderStatus.inDelivery => 'В пути',
        OrderStatus.delivered => 'Доставлен',
        OrderStatus.cancelled => 'Отменён',
        OrderStatus.refunded => 'Возврат',
      };

  @override
  ConsumerState<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends ConsumerState<OrderStatusScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Ресторан/курьер меняют статус через отдельные приложения — без опроса
    // этот экран навсегда остался бы на статусе на момент открытия. Останов
    // сам, как только заказ дойдёт до конечного статуса — дальше ему
    // меняться некуда.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final current = ref.read(orderByIdProvider(widget.orderId)).valueOrNull;
      if (current != null && OrderStatusScreen._terminal.contains(current.status)) {
        timer.cancel();
        return;
      }
      ref.invalidate(orderByIdProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Заказ')),
      body: orderAsync.when(
        loading: () => const _StatusSkeleton(),
        error: (error, stack) => SwErrorState(
          title: 'Не удалось загрузить заказ',
          details: '$error',
          onRetry: () => ref.invalidate(orderByIdProvider(widget.orderId)),
        ),
        data: (order) {
          final terminated = order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded;
          return ListView(
            padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.md, SwSpacing.screenH, SwSpacing.xxxl),
            children: [
              Text(OrderStatusScreen.label(order.status), style: SwTypography.h1.copyWith(color: scheme.onSurface)),
              const SizedBox(height: SwSpacing.xs),
              Text('Заказ ${order.id}', style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: SwSpacing.xxl),
              if (terminated)
                _TerminalNotice(status: order.status)
              else
                _Timeline(current: order.status),
              const Divider(height: SwSpacing.xxxl),
              Text('Состав', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
              const SizedBox(height: SwSpacing.md),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: SwSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text('${line.quantity}×',
                            style: SwTypography.price.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text(line.name, style: SwTypography.body.copyWith(color: scheme.onSurface)),
                      ),
                      Text(
                        formatRub(line.unitPriceRub * line.quantity),
                        style: SwTypography.price.copyWith(color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
              const Divider(height: SwSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
                  Text(formatRub(order.totalRub), style: SwTypography.priceLarge.copyWith(color: scheme.onSurface)),
                ],
              ),
              const SizedBox(height: SwSpacing.xxl),
              // Этот экран часто открывается через go() сразу после оплаты
              // (без стека навигации, там нет системной кнопки «назад»), а
              // также из истории заказов (push, там она есть) — кнопка нужна
              // в обоих случаях, поэтому не полагаемся на AppBar.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('На главную'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Вертикальный таймлайн. Состояние этапа передаётся не только цветом, но и
/// иконкой с толщиной шрифта — цвет в одиночку не является доступным
/// признаком.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.current});

  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = OrderStatusScreen._flow.indexOf(current);

    return Column(
      children: [
        for (var i = 0; i < OrderStatusScreen._flow.length; i++)
          _Step(
            label: OrderStatusScreen.label(OrderStatusScreen._flow[i]),
            done: i < index,
            active: i == index,
            last: i == OrderStatusScreen._flow.length - 1,
            scheme: scheme,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.active,
    required this.last,
    required this.scheme,
  });

  final String label;
  final bool done;
  final bool active;
  final bool last;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    final color = active
        ? scheme.primary
        : done
            ? scheme.onSurfaceVariant
            : scheme.outlineVariant;

    return Semantics(
      label: '$label: ${active ? "текущий этап" : done ? "пройден" : "впереди"}',
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Icon(
                    active
                        ? Icons.radio_button_checked
                        : done
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                    size: 22,
                    color: color,
                  ),
                  if (!last)
                    Expanded(
                      child: Container(width: 2, color: done ? scheme.onSurfaceVariant : scheme.outlineVariant),
                    ),
                ],
              ),
              const SizedBox(width: SwSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : SwSpacing.xl),
                  child: Text(
                    label,
                    style: (active ? SwTypography.bodyStrong : SwTypography.body).copyWith(
                      color: reached ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Отмена и возврат обрывают путь, поэтому таймлайн для них не рисуем — он
/// подразумевает продолжение, которого не будет.
class _TerminalNotice extends StatelessWidget {
  const _TerminalNotice({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refunded = status == OrderStatus.refunded;
    return Container(
      padding: const EdgeInsets.all(SwSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(refunded ? Icons.replay_rounded : Icons.cancel_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: SwSpacing.md),
          Expanded(
            child: Text(
              refunded ? 'Деньги возвращены на счёт списания.' : 'Заказ отменён.',
              style: SwTypography.body.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(SwSpacing.screenH),
      children: [
        const SwSkeleton(width: 200, height: 26),
        const SizedBox(height: SwSpacing.sm),
        const SwSkeleton(width: 120, height: 13),
        const SizedBox(height: SwSpacing.xxl),
        for (var i = 0; i < 5; i++) ...[
          Row(
            children: [
              const SwSkeleton(width: 22, height: 22, radius: 11),
              const SizedBox(width: SwSpacing.md),
              SwSkeleton(width: 140 + i * 12.0, height: 15),
            ],
          ),
          const SizedBox(height: SwSpacing.xl),
        ],
      ],
    );
  }
}
