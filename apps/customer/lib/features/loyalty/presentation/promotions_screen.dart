import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_promo_banner.dart';
import '../../../core/design_system/widgets/sw_skeleton.dart';
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
        data: (promotions) => promotions.isEmpty
            ? const SwEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'Акций сейчас нет',
                message: 'Загляните позже — предложения появляются регулярно.',
              )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: promotions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final promo = promotions[index];
            return SwPromoBanner(title: promo.title, subtitle: promo.description);
          },
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(SwSpacing.screenH),
          children: [
            for (var i = 0; i < 3; i++) ...[
              const SwSkeleton(width: double.infinity, height: 84, radius: SwSpacing.radiusLg),
              const SizedBox(height: SwSpacing.md),
            ],
          ],
        ),
        error: (error, stack) => SwErrorState(
          title: 'Не удалось загрузить акции',
          details: '$error',
          onRetry: () => ref.invalidate(promotionsProvider),
        ),
      ),
    );
  }
}
