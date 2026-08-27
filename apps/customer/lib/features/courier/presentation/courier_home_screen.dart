import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/models/order.dart';
import '../../../core/utils/money.dart';
import 'providers/courier_providers.dart';

/// Курьерский флейвор: предложения заказов (готовы к выдаче) и то, что
/// курьер уже забрал и везёт. Навигации до точки доставки здесь нет
/// намеренно — эпик 10, ждёт MapProvider/Yandex MapKit.
class CourierHomeScreen extends ConsumerWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offeredOrdersProvider);
    final myDeliveries = ref.watch(myDeliveriesProvider);

    Future<void> accept(Order order) async {
      await ref.read(courierRepositoryProvider).acceptOrder(order.id);
      ref.read(myDeliveriesProvider.notifier).add(order);
      ref.invalidate(offeredOrdersProvider);
    }

    Future<void> deny(Order order) async {
      await ref.read(courierRepositoryProvider).denyOrder(order.id);
      ref.invalidate(offeredOrdersProvider);
    }

    Future<void> deliver(Order order) async {
      await ref.read(courierRepositoryProvider).markDelivered(order.id);
      ref.read(myDeliveriesProvider.notifier).remove(order.id);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(offeredOrdersProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (myDeliveries.isNotEmpty) ...[
              const _SectionHeader('В пути'),
              for (final order in myDeliveries)
                _OrderTile(
                  order: order,
                  // Явная ширина обязательна: у FilledButton есть внутренний
                  // ConstrainedBox с BoxConstraints(w=Infinity) для минимальной
                  // области нажатия — без внешней границы это ломает layout
                  // при неограниченной ширине от родителя (Row отдаёт
                  // не-Expanded детям constraints 0..Infinity).
                  trailing: SizedBox(
                    width: 140,
                    child: FilledButton(
                      onPressed: () => deliver(order),
                      child: const Text('Доставлено'),
                    ),
                  ),
                ),
            ],
            const _SectionHeader('Новые предложения'),
            offersAsync.when(
              data: (orders) => orders.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: SwEmptyState(
                        icon: Icons.delivery_dining_outlined,
                        title: 'Пока нет предложений',
                        message: 'Новые заказы появятся здесь автоматически.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final order in orders)
                          _OrderTile(
                            order: order,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => deny(order),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => accept(order),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SwErrorState(
                title: 'Не удалось загрузить заказы',
                details: '$error',
                onRetry: () => ref.invalidate(offeredOrdersProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.trailing});

  final Order order;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress?.addressText;
    // Плоский Row вместо ListTile: ListTile.trailing даёт ребёнку constraints
    // с бесконечной максимальной шириной, из-за чего FilledButton внутри
    // ломает layout ("Trailing widget consumes the entire tile width").
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Заказ ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'),
                Text(
                  address == null ? formatRub(order.totalRub) : '${formatRub(order.totalRub)} · $address',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
