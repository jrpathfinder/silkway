import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/env/env.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/providers.dart';
import '../routing/app_router.dart';
import 'flavor.dart';

/// Shared entry point for both main_customer.dart and main_courier.dart —
/// the only difference between the two Flutter binaries is which
/// [AppFlavor] is passed here, which drives both `envProvider` and which
/// route table app_router.dart builds.
void runSilkwayApp(AppFlavor flavor) {
  runApp(
    ProviderScope(
      overrides: [
        envProvider.overrideWithValue(Env.fromDartDefines(flavor)),
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Silkway',
      theme: AppTheme.light(),
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
