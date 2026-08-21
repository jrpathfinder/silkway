import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silkway_app/features/splash/presentation/splash_screen.dart';

import 'helpers/pump_helpers.dart';

void main() {
  testWidgets('Customer app boots to the home screen against mocks', (WidgetTester tester) async {
    await pumpAppPastSplash(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('на повторном запуске заставка пропускается и сразу открывается меню', (tester) async {
    // showSplash: false — то, что SplashGate вернёт, если заставку уже
    // показывали недавно (см. runSilkwayApp).
    await pumpAppPastSplash(tester, showSplash: false);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
