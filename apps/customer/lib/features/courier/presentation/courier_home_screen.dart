import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import 'providers/courier_providers.dart';

/// Courier flavor's landing screen: accept/deny incoming order offers.
/// Full pickup/dropoff navigation (epic 10) is deferred to the next slice,
/// once MapProvider/Yandex MapKit is wired in — this proves the flavor split
/// and the repository pattern for the courier surface now.
class CourierHomeScreen extends ConsumerWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offeredOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: offersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('Пока нет предложений заказов'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text('Заказ ${order.id}'),
                    subtitle: Text(formatRub(order.totalRub)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => ref.read(courierRepositoryProvider).denyOrder(order.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => ref.read(courierRepositoryProvider).acceptOrder(order.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}
