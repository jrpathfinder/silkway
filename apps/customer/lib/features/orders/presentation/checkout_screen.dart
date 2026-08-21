import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Товаров: ${cart.itemCount}'),
            const SizedBox(height: 8),
            Text(
              'Итого: ${formatRub(cart.totalRub)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _placing ? null : _placeOrder,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _placing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Оплатить'),
            ),
          ],
        ),
      ),
    );
  }
}
