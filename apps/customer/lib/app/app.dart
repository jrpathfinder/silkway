import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/design_system/theme/theme_mode_notifier.dart';
import '../core/env/env.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/providers.dart';
import '../core/storage/local_kv.dart';
import '../features/splash/application/splash_gate.dart';
import '../routing/app_router.dart';
import 'flavor.dart';

/// Shared entry point for both main_customer.dart and main_courier.dart —
/// the only difference between the two Flutter binaries is which
/// [AppFlavor] is passed here, which drives both `envProvider` and which
/// route table app_router.dart builds.
Future<void> runSilkwayApp(AppFlavor flavor) async {
  // Нужно до обращения к SharedPreferences внутри SplashGate.
  WidgetsFlutterBinding.ensureInitialized();

  // Решение о заставке принимаем до runApp: роутер выбирает стартовый
  // маршрут синхронно, а хранилище читается асинхронно. Чтение занимает
  // единицы миллисекунд и происходит, пока на экране ещё нативная заставка,
  // так что задержки не видно.
  //
  // Если хранилище недоступно, показываем заставку: пропуск — оптимизация,
  // и она не должна ломать запуск.
  final gate = SplashGate(LocalKv());
  var showSplash = true;
  try {
    showSplash = await gate.shouldShow();
    if (showSplash) await gate.markShown();
  } catch (_) {
    showSplash = true;
  }

  runApp(
    ProviderScope(
      overrides: [
        envProvider.overrideWithValue(Env.fromDartDefines(flavor)),
        showSplashProvider.overrideWithValue(showSplash),
      ],
      child: const SilkwayApp(),
    ),
  );
}

class SilkwayApp extends ConsumerWidget {
  const SilkwayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Пока LocalKv ещё читается — доля секунды на первом кадре — падаем
    // обратно на system, а не блокируем запуск на этом чтении.
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Silkway',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
