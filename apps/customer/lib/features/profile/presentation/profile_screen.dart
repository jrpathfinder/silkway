import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../auth/application/session_notifier.dart';
import '../application/profile_notifier.dart';

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
      body: sessionAsync.when(
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
