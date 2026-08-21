import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/widgets/sw_promo_banner.dart';
import 'providers/loyalty_providers.dart';

/// Список акций. Пока только на моках: модуля лояльности на бэкенде нет.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Все акции')),
      body: promotionsAsync.when(
        data: (promotions) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: promotions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final promo = promotions[index];
            return SwPromoBanner(title: promo.title, subtitle: promo.description);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}
