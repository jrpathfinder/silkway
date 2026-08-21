import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/app/app.dart';
import 'package:silkway_app/core/env/env.dart';
import 'package:silkway_app/features/splash/presentation/splash_screen.dart';

import 'fakes.dart';

/// Запускает приложение и пропускает брендовую видео-заставку, оставляя на
/// экране первый «настоящий» экран.
///
/// Оба флейвора теперь стартуют со [SplashScreen] (см. app_router.dart), а у
/// video_player нет реализации под `flutter test`. Поэтому вместо того чтобы
/// полагаться на поведение видео-контроллера без платформы, тест использует
/// штатный пропуск по тапу — ровно то же, что делает торопящийся
/// пользователь.
Future<void> pumpAppPastSplash(WidgetTester tester, {Env env = testMockEnv}) async {
  await tester.pumpWidget(ProviderScope(overrides: testOverrides(env: env), child: const SilkwayApp()));
  await tester.pump();

  final splash = find.byType(SplashScreen);
  if (splash.evaluate().isNotEmpty) {
    await tester.tap(splash);
  }
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view if it sits inside a Scrollable (the item-detail
/// sheet's content can be taller than the test viewport — see
/// ItemDetailSheet), taps it, and settles, then deterministically clears any
/// toast the tap triggered (see showSwToast). Toasts float at the bottom of
/// the screen — the same place as sticky CTA bars and bottom navigation — so
/// a still-visible one can swallow a later tap there; pumpAndSettle alone
/// won't wait it out since it only keeps pumping while frames are actively
/// scheduled, not for a dormant Timer counting down to auto-dismiss. Use this
/// instead of a bare tap+pumpAndSettle for any tap inside the sheet, or one
/// that might show a toast.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isNotEmpty) {
    ScaffoldMessenger.of(tester.element(scaffolds.first)).clearSnackBars();
  }
  await tester.pumpAndSettle();
}
