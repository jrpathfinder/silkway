import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/theme/theme_mode_notifier.dart';
import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/models/delivery.dart';
import '../../auth/application/session_notifier.dart';
import '../application/profile_notifier.dart';
import '../application/saved_addresses_notifier.dart';

/// Профиль: вход/выход, имя/email и переходы в заказы и акции.
///
/// Каталог и корзина доступны без авторизации — вход требуется только на
/// оформлении заказа (см. [checkoutRedirectGuard]).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      // Переключатель темы — вне sessionAsync.when: тема должна быть доступна
      // и без входа, каталог с корзиной и так открыты неавторизованным.
      body: Column(
        children: [
          const _ThemeModeSwitcher(),
          const Divider(height: 1),
          Expanded(
            child: sessionAsync.when(
              data: (session) => session.isAuthenticated
                  ? _AuthenticatedProfile(phone: session.phone ?? '')
                  : Center(
                      child: FilledButton(
                        onPressed: () => context.push('/auth/phone'),
                        child: const Text('Войти'),
                      ),
                    ),
              // Профиль читается из локального хранилища и открывается практически
              // мгновенно — скелетон тут был бы заметнее самой загрузки.
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => SwErrorState(
                title: 'Не удалось открыть профиль',
                details: '$error',
                onRetry: () => ref.invalidate(sessionNotifierProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedProfile extends ConsumerStatefulWidget {
  const _AuthenticatedProfile({required this.phone});

  final String phone;

  @override
  ConsumerState<_AuthenticatedProfile> createState() => _AuthenticatedProfileState();
}

class _AuthenticatedProfileState extends ConsumerState<_AuthenticatedProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileNotifierProvider.notifier).save(
            name: _nameController.text,
            email: _emailController.text,
          );
      if (mounted) showSwToast(context, 'Профиль сохранён');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(profileNotifierProvider);

    // Поля заполняем один раз, когда профиль подгрузился из LocalKv — иначе
    // при каждом ребилде контроллеры затирали бы то, что человек уже набрал.
    profileAsync.whenData((profile) {
      if (!_prefilled) {
        _nameController.text = profile.name ?? '';
        _emailController.text = profile.email ?? '';
        _prefilled = true;
      }
    });

    return ListView(
      padding: const EdgeInsets.all(SwSpacing.screenH),
      children: [
        Text(widget.phone, style: SwTypography.h2.copyWith(color: scheme.onSurface)),
        const SizedBox(height: SwSpacing.xl),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Имя'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: SwSpacing.md),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: SwSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Сохраняем…' : 'Сохранить'),
          ),
        ),
        const SizedBox(height: SwSpacing.xxl),
        const _SavedAddressesSection(),
        const SizedBox(height: SwSpacing.xxl),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Мои заказы'),
          onTap: () => context.push('/orders'),
        ),
        ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: const Text('Акции'),
          onTap: () => context.push('/promotions'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Выйти'),
          onTap: () => ref.read(sessionNotifierProvider.notifier).logout(),
        ),
      ],
    );
  }
}

/// Адресная книга: сохранённые адреса доставки с отметкой «по умолчанию».
/// Тап по строке делает её адресом по умолчанию — им предзаполняется адрес
/// на оформлении заказа (см. CheckoutScreen).
class _SavedAddressesSection extends ConsumerWidget {
  const _SavedAddressesSection();

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final result = await context.push<DeliveryAddress>('/checkout/address');
    if (result != null) {
      await ref.read(savedAddressesProvider.notifier).add(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final addresses = ref.watch(savedAddressesProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Мои адреса', style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: SwSpacing.sm),
        for (final saved in addresses)
          Card(
            margin: const EdgeInsets.only(bottom: SwSpacing.sm),
            child: ListTile(
              leading: Icon(
                saved.isDefault ? Icons.star : Icons.star_border,
                color: saved.isDefault ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(saved.address.addressText, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: saved.address.comment != null ? Text(saved.address.comment!) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(savedAddressesProvider.notifier).remove(saved.id),
              ),
              onTap: saved.isDefault ? null : () => ref.read(savedAddressesProvider.notifier).setDefault(saved.id),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _addAddress(context, ref),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Добавить адрес'),
        ),
      ],
    );
  }
}

class _ThemeModeSwitcher extends ConsumerWidget {
  const _ThemeModeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.md, SwSpacing.screenH, SwSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Тема', style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: SwSpacing.sm),
          SegmentedButton<ThemeMode>(
            // tooltip: '' на каждом сегменте — иначе SegmentedButton вешает
            // на них Tooltip с оверлеем на весь экран, который в виджет-тестах
            // перехватывает тапы по всему, что отрисовано ниже (см. "Выйти"
            // в profile_orders_promotions_test.dart).
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Авто'), tooltip: ''),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Светлая'), tooltip: ''),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Тёмная'), tooltip: ''),
            ],
            selected: {current},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).setThemeMode(selection.first),
          ),
        ],
      ),
    );
  }
}
