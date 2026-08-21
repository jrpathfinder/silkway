import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart';
import '../../../core/utils/money.dart';
import 'providers/orders_providers.dart';

/// Статус конкретного заказа с составом и итоговой суммой.
///
/// Финальная точка потока: сюда переходят после оплаты.
class OrderStatusScreen extends ConsumerWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Заказ')),
      body: orderAsync.when(
        data: (order) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Заказ ${order.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Chip(label: Text(_statusLabel(order.status))),
              const SizedBox(height: 16),
              for (final line in order.lines)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${line.name} × ${line.quantity}'),
                  trailing: Text(formatRub(line.unitPriceRub * line.quantity)),
                ),
              const Divider(),
              Text('Итого: ${formatRub(order.totalRub)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  String _statusLabel(OrderStatus status) => switch (status) {
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
}
