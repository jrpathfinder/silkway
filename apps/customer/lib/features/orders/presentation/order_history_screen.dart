import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../auth/application/session_notifier.dart';
import 'providers/orders_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider).valueOrNull;
    final customerId = session?.customerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: customerId == null
          ? const Center(child: Text('Войдите, чтобы увидеть заказы'))
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
    return ordersAsync.when(
      data: (orders) => orders.isEmpty
          ? const Center(child: Text('Заказов пока нет'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Заказ ${order.id}'),
                  subtitle: Text(formatRub(order.totalRub)),
                  onTap: () => context.push('/orders/${order.id}'),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ошибка: $error')),
    );
  }
}
