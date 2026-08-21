import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';

void main() {
  testWidgets(
    'unauthenticated checkout is gated behind phone+OTP, then completes to an order status',
    (tester) async {
      await pumpAppPastSplash(tester);

      // Add an item and go to the cart.
      await tester.tap(find.text('Самса с бараниной'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Добавить в корзину'));
      await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
      await tester.pumpAndSettle();

      // Checkout is gated at checkout — this redirects to phone entry.
      await tester.tap(find.text('Оформить заказ'));
      await tester.pumpAndSettle();

      expect(find.text('Введите номер телефона'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '+79990000000');
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();

      // Wrong code shows an inline toast and stays on the OTP screen. Pump a
      // bounded duration (past the mock's 200ms verify delay) rather than
      // pumpAndSettle, which would run the fake clock through the toast's
      // full 2s auto-dismiss before we get to assert on it.
      expect(find.textContaining('+79990000000'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '1111');
      await tester.tap(find.text('Подтвердить'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Неверный код'), findsOneWidget);
      // pumpAndSettle won't wait out the toast's bare Timer-based dismissal
      // (it only keeps pumping while frames are actively being scheduled) —
      // clear it deterministically so it's gone before the next tap.
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
      await tester.pumpAndSettle();

      // The mock dev code succeeds and returns to checkout, now authenticated.
      await tester.enterText(find.byType(TextField).last, '0000');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      expect(find.text('Оформление заказа'), findsOneWidget);
      expect(find.text('Товаров: 1'), findsOneWidget);

      await tester.tap(find.text('Оплатить'));
      await tester.pumpAndSettle();

      // Payment webview screen (mock mode) auto-advances to the order status.
      expect(find.textContaining('Заказ'), findsWidgets);
      expect(find.text('Оплачен'), findsOneWidget);
      expect(find.text('Самса с бараниной × 1'), findsOneWidget);
    },
  );
}
