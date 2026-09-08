import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silkway_app/features/catalog/presentation/home_screen.dart';

import '../helpers/pump_helpers.dart';

void main() {
  testWidgets(
    'unauthenticated checkout is gated behind phone+OTP, then completes to an order status',
    (tester) async {
      await pumpAppPastSplash(tester);

      // Add an item and go to the cart.
      // «Самса» лежит во втором разделе меню, до неё нужно доскроллить:
      // списки разделов ленивые.
      await tester.scrollUntilVisible(
        find.text('Самса с бараниной'),
        200,
        scrollable: find.descendant(
          of: find.byKey(HomeScreen.menuListKey),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.ensureVisible(find.text('Самса с бараниной'));
      await tester.pumpAndSettle();
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
      // Экран показывает состав заказа, а не только количество позиций.
      expect(find.text('Самса с бараниной'), findsOneWidget);
      expect(find.text('К оплате'), findsOneWidget);

      // По умолчанию выбрана доставка, а для неё нужен адрес — кнопка
      // «Оплатить» недоступна, пока его не указали. Этот тест проверяет
      // не доставку, а сам платёжный поток, поэтому переключаемся на
      // самовывоз — так адрес не нужен.
      await tapAndSettle(tester, find.text('Самовывоз'));
      await tester.tap(find.text('Оплатить'));
      await tester.pumpAndSettle();

      // Payment webview screen (mock mode) auto-advances to the order status.
      // Статус встречается дважды: крупным заголовком и этапом в таймлайне.
      expect(find.text('Оплачен'), findsNWidgets(2));
      expect(find.text('Состав'), findsOneWidget);
      // Количество теперь отдельной колонкой, поэтому название ищем само по
      // себе, а не строкой «Самса × 1».
      expect(find.text('Самса с бараниной'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
    },
  );
}
