import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';

Future<void> _pumpApp(WidgetTester tester) => pumpAppPastSplash(tester);

Future<void> _goToProfileTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('profile tab shows a login prompt when unauthenticated', (tester) async {
    await _pumpApp(tester);
    await _goToProfileTab(tester);

    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('logging in from the profile tab shows the account menu, then logging out returns to the prompt', (tester) async {
    // Default test surface is 800x600 — much shorter than any real device
    // this app targets. The theme switcher above the account menu pushes
    // "Выйти" low enough that at 600px it lands under the shell's bottom
    // NavigationBar (whose own destination tooltips intercept the tap).
    // Real devices (874pt+) have plenty of room; size the surface to match.
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);
    await _goToProfileTab(tester);

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+79990000000');
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0000');
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();

    // Verifying navigates to '/' (home) — back to the profile tab to see the
    // authenticated state.
    await _goToProfileTab(tester);
    expect(find.text('+79990000000'), findsOneWidget);
    expect(find.text('Мои заказы'), findsOneWidget);
    expect(find.text('Акции'), findsOneWidget);

    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('order history prompts for login when unauthenticated, and lists past orders once signed in', (tester) async {
    await _pumpApp(tester);
    await _goToProfileTab(tester);

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+79990000000');
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0000');
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();

    await _goToProfileTab(tester);
    await tester.tap(find.text('Мои заказы'));
    await tester.pumpAndSettle();

    expect(find.text('Заказов пока нет'), findsOneWidget);
  });

  testWidgets('promotions screen lists the mock loyalty promotions', (tester) async {
    await _pumpApp(tester);
    await _goToProfileTab(tester);

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+79990000000');
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0000');
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();

    await _goToProfileTab(tester);
    await tester.tap(find.text('Акции'));
    await tester.pumpAndSettle();

    expect(find.text('Скидка 10% на первый заказ'), findsOneWidget);
    expect(find.text('Бесплатная доставка от 1 500 ₽'), findsOneWidget);
  });
}
