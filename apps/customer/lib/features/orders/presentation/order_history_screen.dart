import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_skeleton.dart';
import '../../../core/utils/money.dart';
import '../../auth/application/session_notifier.dart';
import 'order_status_screen.dart';
import 'providers/orders_providers.dart';

/// История заказов покупателя.
///
/// Работает только на моках: роута для списка заказов на бэкенде нет
/// (см. OrdersRepositoryHttp.listForCustomer).
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider).valueOrNull;
    final customerId = session?.customerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: customerId == null
          ? SwEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Нужен вход',
              message: 'Войдите, чтобы увидеть свои заказы.',
              actionLabel: 'Войти',
              onAction: () => context.push('/auth/phone'),
            )
          : _OrderList(customerId: customerId),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersForCustomerProvider(customerId));
    final scheme = Theme.of(context).colorScheme;

    return ordersAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(SwSpacing.screenH),
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SwSkeleton(width: double.infinity, height: 76, radius: SwSpacing.radiusLg),
            const SizedBox(height: SwSpacing.md),
          ],
        ],
      ),
      error: (error, stack) => SwErrorState(
        title: 'Не удалось загрузить заказы',
        details: '$error',
        onRetry: () => ref.invalidate(ordersForCustomerProvider(customerId)),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return SwEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Заказов пока нет',
            message: 'Первый заказ появится здесь сразу после оформления.',
            actionLabel: 'Открыть меню',
            onAction: () => context.go('/'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(SwSpacing.screenH),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: SwSpacing.md),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
              child: InkWell(
                borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
                onTap: () => context.push('/orders/${order.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(SwSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              OrderStatusScreen.label(order.status),
                              style: SwTypography.h3.copyWith(color: scheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.lines.length} позиц. · ${order.id}',
                              style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: SwSpacing.md),
                      Text(formatRub(order.totalRub), style: SwTypography.price.copyWith(color: scheme.onSurface)),
                      Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
