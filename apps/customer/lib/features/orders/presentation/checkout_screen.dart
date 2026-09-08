import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_category_chip.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/models/delivery.dart';
import '../../../core/models/order.dart';
import '../../../core/ports/orders_repository.dart';
import '../../../core/providers.dart';
import '../../../core/utils/idempotency_key_store.dart';
import '../../../core/utils/money.dart';
import '../../auth/application/session_notifier.dart';
import '../../cart/application/cart_notifier.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import '../../profile/application/saved_addresses_notifier.dart';
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
  bool _addressPrefilled = false;
  FulfillmentType _fulfillmentType = FulfillmentType.delivery;
  DeliveryAddress? _address;

  /// Открывает выбор адреса: сохранённые + из истории заказов + карта для
  /// нового. Отдельный экран с картой (`/checkout/address`) остаётся входом
  /// для «Новый адрес», а не единственным способом указать адрес.
  Future<void> _pickAddress() async {
    final choice = await showModalBottomSheet<_AddressChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressPickerSheet(current: _address),
    );
    if (choice == null || !mounted) return;

    if (choice.openMapPicker) {
      final result = await context.push<DeliveryAddress>('/checkout/address', extra: _address);
      if (result != null && mounted) {
        setState(() => _address = result);
        _offerToSaveAddress(result);
      }
      return;
    }
    setState(() => _address = choice.address);
  }

  void _offerToSaveAddress(DeliveryAddress address) {
    final saved = ref.read(savedAddressesProvider).valueOrNull ?? const [];
    if (saved.any((a) => a.address.addressText == address.addressText)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Сохранить адрес для следующих заказов?'),
        action: SnackBarAction(
          label: 'Сохранить',
          onPressed: () => ref.read(savedAddressesProvider.notifier).add(address),
        ),
      ),
    );
  }

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
            fulfillmentType: _fulfillmentType,
            deliveryAddress: _fulfillmentType == FulfillmentType.delivery ? _address : null,
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
    final locationId = ref.watch(selectedLocationIdProvider);
    final locations = ref.watch(activeLocationsProvider).valueOrNull ?? const [];
    final matchingLocations = locations.where((l) => l.id == locationId);
    final selectedLocation = matchingLocations.isEmpty ? null : matchingLocations.first;

    // Предзаполняем адресом по умолчанию из адресной книги один раз, когда
    // она подгрузилась — тот же приём, что и в ProfileScreen для полей
    // имени/email, чтобы не затирать выбор, если пользователь уже открывал
    // карту вручную до того, как книга успела загрузиться.
    ref.watch(savedAddressesProvider).whenData((addresses) {
      if (_addressPrefilled) return;
      _addressPrefilled = true;
      final defaults = addresses.where((a) => a.isDefault);
      if (_address == null && defaults.isNotEmpty) {
        _address = defaults.first.address;
      }
    });

    final needsAddress = _fulfillmentType == FulfillmentType.delivery && _address == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.md, SwSpacing.screenH, SwSpacing.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: SwCategoryChip(
                  label: 'Доставка',
                  selected: _fulfillmentType == FulfillmentType.delivery,
                  onTap: () => setState(() => _fulfillmentType = FulfillmentType.delivery),
                ),
              ),
              const SizedBox(width: SwSpacing.sm),
              Expanded(
                child: SwCategoryChip(
                  label: 'Самовывоз',
                  selected: _fulfillmentType == FulfillmentType.pickup,
                  onTap: () => setState(() => _fulfillmentType = FulfillmentType.pickup),
                ),
              ),
            ],
          ),
          const SizedBox(height: SwSpacing.md),
          if (_fulfillmentType == FulfillmentType.delivery)
            _AddressRow(address: _address, onTap: _pickAddress)
          else if (selectedLocation != null)
            _PickupRow(address: selectedLocation.address),
          const SizedBox(height: SwSpacing.xl),
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
              label: needsAddress ? 'Укажите адрес' : 'Оплатить',
              priceLabel: formatRub(cart.totalRub),
              enabled: !needsAddress,
              onTap: needsAddress ? _pickAddress : _placeOrder,
            ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.onTap});

  final DeliveryAddress? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SwSpacing.lg, vertical: SwSpacing.md),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: scheme.primary),
              const SizedBox(width: SwSpacing.md),
              Expanded(
                child: address == null
                    ? Text('Укажите адрес доставки', style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address!.addressText,
                            style: SwTypography.bodyStrong.copyWith(color: scheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address!.comment != null)
                            Text(address!.comment!, style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SwSpacing.lg, vertical: SwSpacing.md),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(SwSpacing.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, color: scheme.primary),
          const SizedBox(width: SwSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Заберите из ресторана', style: SwTypography.bodyStrong.copyWith(color: scheme.onSurface)),
                Text(address, style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressChoice {
  const _AddressChoice({this.address, this.openMapPicker = false});

  final DeliveryAddress? address;
  final bool openMapPicker;
}

/// Лист выбора адреса: сохранённые адреса из адресной книги, затем адреса
/// из прошлых заказов (пропуская те, что уже сохранены — не дублировать),
/// и «Новый адрес» — вход на карту.
class _AddressPickerSheet extends ConsumerWidget {
  const _AddressPickerSheet({required this.current});

  final DeliveryAddress? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final saved = ref.watch(savedAddressesProvider).valueOrNull ?? const [];
    final customerId = ref.watch(sessionNotifierProvider).valueOrNull?.customerId;
    final history = customerId == null
        ? const <Order>[]
        : ref.watch(ordersForCustomerProvider(customerId)).valueOrNull ?? const <Order>[];

    final savedTexts = saved.map((a) => a.address.addressText).toSet();
    final historyAddresses = <String, DeliveryAddress>{};
    for (final order in history) {
      final address = order.deliveryAddress;
      if (address == null || savedTexts.contains(address.addressText)) continue;
      historyAddresses[address.addressText] = address;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Адрес доставки', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
            const SizedBox(height: SwSpacing.md),
            for (final s in saved)
              _AddressTile(
                icon: s.isDefault ? Icons.star : Icons.location_on_outlined,
                title: s.address.addressText,
                subtitle: s.address.comment,
                selected: current?.addressText == s.address.addressText,
                onTap: () => Navigator.of(context).pop(_AddressChoice(address: s.address)),
              ),
            if (historyAddresses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: SwSpacing.sm),
                child: Text('Из истории заказов', style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
              ),
              for (final address in historyAddresses.values)
                _AddressTile(
                  icon: Icons.history,
                  title: address.addressText,
                  subtitle: address.comment,
                  selected: current?.addressText == address.addressText,
                  onTap: () => Navigator.of(context).pop(_AddressChoice(address: address)),
                ),
            ],
            const SizedBox(height: SwSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.add_location_alt_outlined, color: scheme.primary),
              title: Text('Новый адрес', style: SwTypography.bodyStrong.copyWith(color: scheme.primary)),
              onTap: () => Navigator.of(context).pop(const _AddressChoice(openMapPicker: true)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.icon, required this.title, required this.selected, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}
