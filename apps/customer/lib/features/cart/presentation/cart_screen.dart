import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/widgets/sw_promo_banner.dart';
import '../../../core/design_system/widgets/sw_quantity_stepper.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/utils/money.dart';
import '../application/cart_notifier.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: cart.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Товаров: ${cart.itemCount}'),
                      Text('Итого: ${formatRub(cart.totalRub)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SwPromoBanner(
                  title: 'Бесплатная доставка от 1 500 ₽',
                  subtitle: 'Добавьте ещё блюд, чтобы получить бесплатную доставку',
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < cart.lines.length; i++) ...[
                  _CartLineTile(index: i),
                  const Divider(),
                ],
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SwStickyCtaBar(
              label: 'Оформить заказ',
              priceLabel: formatRub(cart.totalRub),
              onTap: () => context.push('/checkout'),
            ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(cartNotifierProvider).lines[index];
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (line.selectedModifiers.isNotEmpty)
                Text(
                  line.selectedModifiers.map((m) => m.name).join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(formatRub(line.totalRub)),
            ],
          ),
        ),
        SwQuantityStepper(
          quantity: line.quantity,
          onIncrement: () => notifier.updateQuantity(index, line.quantity + 1),
          onDecrement: () => notifier.updateQuantity(index, line.quantity - 1),
          minQuantity: 0,
        ),
        IconButton(
          onPressed: () => notifier.removeLine(index),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
