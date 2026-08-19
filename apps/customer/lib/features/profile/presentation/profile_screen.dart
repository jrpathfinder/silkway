import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/session_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: sessionAsync.when(
        data: (session) => session.isAuthenticated
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.phone ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
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
                ),
              )
            : Center(
                child: FilledButton(
                  onPressed: () => context.push('/auth/phone'),
                  child: const Text('Войти'),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}
