import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/ports/orders_repository.dart';
import '../../../core/providers.dart';
import '../../../core/utils/idempotency_key_store.dart';
import '../../../core/utils/money.dart';
import '../../auth/application/session_notifier.dart';
import '../../cart/application/cart_notifier.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import 'providers/orders_providers.dart';

/// Оформление заказа: подтверждение состава и создание заказа.
///
/// Экран под защитой [checkoutRedirectGuard] — сюда не попасть без авторизации.
/// Ключ идемпотентности берётся из [IdempotencyKeyStore] и переживает
/// перезапуск приложения, поэтому повторная отправка не создаст второй заказ.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _placing = false;

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      final cart = ref.read(cartNotifierProvider);
      final session = ref.read(sessionNotifierProvider).valueOrNull;
      final locationId = ref.read(selectedLocationIdProvider);
      if (cart.isEmpty || session?.customerId == null || locationId == null) return;

      // Idempotency key persists per cart fingerprint (core/utils) — an app
      // kill-and-relaunch mid-checkout with an unchanged cart reuses the
      // same key, so a retried POST /v1/orders hits the backend's
      // idempotency map instead of creating a duplicate order.
      final keyStore = IdempotencyKeyStore(ref.read(localKvProvider));
      final fingerprint = cart.fingerprint;
      final idempotencyKey = await keyStore.getOrCreate(fingerprint, () => const Uuid().v4());

      final order = await ref.read(ordersRepositoryProvider).create(
            locationId: locationId,
            customerId: session!.customerId!,
            lines: [
              for (final line in cart.lines)
                CreateOrderLineInput(
                  itemId: line.item.id,
                  quantity: line.quantity,
                  modifierIds: line.selectedModifiers.map((m) => m.id).toList(),
                ),
            ],
            idempotencyKey: idempotencyKey,
          );

      await keyStore.clear(fingerprint);
      ref.read(cartNotifierProvider.notifier).clear();

      if (!mounted) return;
      context.go('/checkout/payment?orderId=${order.id}');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.md, SwSpacing.screenH, SwSpacing.xl),
        children: [
          Text('Заказ', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
          const SizedBox(height: SwSpacing.md),
          for (final line in cart.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: SwSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Количество отдельным столбцом: так строки выравниваются
                  // по названию, а не пляшут в зависимости от числа.
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${line.quantity}×',
                      style: SwTypography.price.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.item.name, style: SwTypography.body.copyWith(color: scheme.onSurface)),
                        if (line.selectedModifiers.isNotEmpty)
                          Text(
                            line.selectedModifiers.map((m) => m.name).join(', '),
                            style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SwSpacing.sm),
                  Text(formatRub(line.totalRub), style: SwTypography.price.copyWith(color: scheme.onSurface)),
                ],
              ),
            ),
          const Divider(height: SwSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('К оплате', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
              Text(formatRub(cart.totalRub), style: SwTypography.priceLarge.copyWith(color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: SwSpacing.sm),
          // Честное предупреждение вместо выдуманных строк доставки и сборов:
          // сервер пересчитывает стоимость по каталогу и клиентским суммам
          // не доверяет, поэтому итог может отличаться.
          Text(
            'Стоимость подтвердит ресторан: цены пересчитываются при создании заказа.',
            style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      bottomNavigationBar: _placing
          ? const Padding(
              padding: EdgeInsets.all(SwSpacing.xl),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          : SwStickyCtaBar(
              label: 'Оплатить',
              priceLabel: formatRub(cart.totalRub),
              onTap: _placeOrder,
            ),
    );
  }
}
