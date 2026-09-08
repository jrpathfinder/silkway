import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/dish_image.dart';
import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_quantity_stepper.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/utils/money.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import '../application/cart_notifier.dart';
import '../domain/cart.dart';

/// Корзина.
///
/// Отвечает сразу на два вопроса: что я заказал и сколько это стоит.
/// Количество меняется прямо здесь, уходить с экрана не нужно.
///
/// Строк «доставка», «сервисный сбор» и «скидка» тут намеренно нет: этих
/// данных нет ни в моделях, ни в API. Показать их прочерками означало бы
/// пообещать то, чего приложение пока не умеет.
///
/// Суммы на экране — клиентская оценка для показа. Итог всё равно
/// пересчитывает сервер при создании заказа.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Корзина')),
        body: SwEmptyState(
          icon: Icons.shopping_basket_outlined,
          title: 'Корзина пуста',
          message: 'Загляните в меню — плов уже ждёт.',
          actionLabel: 'Открыть меню',
          onAction: () => context.go('/'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, 0, SwSpacing.screenH, SwSpacing.xl),
        children: [
          const _BranchLine(),
          const SizedBox(height: SwSpacing.md),
          for (var i = 0; i < cart.lines.length; i++) ...[
            _CartLineTile(index: i),
            if (i != cart.lines.length - 1) const Divider(height: SwSpacing.xxl),
          ],
          const SizedBox(height: SwSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Товаров: ${cart.itemCount}', style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant)),
              Text(formatRub(cart.totalRub), style: SwTypography.priceLarge.copyWith(color: scheme.onSurface)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SwStickyCtaBar(
        label: 'Оформить заказ',
        priceLabel: formatRub(cart.totalRub),
        onTap: () => context.push('/checkout'),
      ),
    );
  }
}

/// Из какого филиала заказ. Важно, когда филиалов несколько: корзина
/// привязана к одному, и подменять его молча нельзя.
class _BranchLine extends ConsumerWidget {
  const _BranchLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final locationId = ref.watch(cartNotifierProvider).locationId;
    final name = ref.watch(activeLocationsProvider).maybeWhen(
          data: (locations) {
            final match = locations.where((l) => l.id == locationId);
            return match.isNotEmpty ? match.first.name : null;
          },
          orElse: () => null,
        );
    if (name == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.storefront_outlined, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: SwSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    // Строку могли удалить, пока перестраивался кадр, — молча выходим, иначе
    // получим RangeError.
    if (index >= cart.lines.length) return const SizedBox.shrink();

    final CartLine line = cart.lines[index];
    final notifier = ref.read(cartNotifierProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
          child: SizedBox(
            width: 64,
            height: 64,
            child: DishImage(imageUrl: line.item.imageUrl, borderRadius: BorderRadius.zero),
          ),
        ),
        const SizedBox(width: SwSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.item.name, style: SwTypography.h3.copyWith(color: scheme.onSurface)),
              if (line.selectedModifiers.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  line.selectedModifiers.map((m) => m.name).join(', '),
                  style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: SwSpacing.sm),
              Text(formatRub(line.totalRub), style: SwTypography.price.copyWith(color: scheme.onSurface)),
              const SizedBox(height: SwSpacing.sm),
              Row(
                children: [
                  SwQuantityStepper(
                    quantity: line.quantity,
                    onIncrement: () => notifier.updateQuantity(index, line.quantity + 1),
                    onDecrement: () => notifier.updateQuantity(index, line.quantity - 1),
                    // 0 разрешаем: уменьшение до нуля удаляет строку — это
                    // привычнее, чем искать отдельную кнопку.
                    minQuantity: 0,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => notifier.removeLine(index),
                    icon: const Icon(Icons.delete_outline),
                    color: scheme.onSurfaceVariant,
                    tooltip: 'Убрать ${line.item.name}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
