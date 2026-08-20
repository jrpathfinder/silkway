import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/app/app.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_helpers.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const SilkwayApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('browsing, adding to cart, and editing the cart line', (tester) async {
    await _pumpApp(tester);

    // Home screen shows the mock catalog.
    expect(find.text('Плов классический'), findsOneWidget);
    expect(find.text('Самса с бараниной'), findsOneWidget);

    // Open the item-detail sheet.
    await tester.tap(find.text('Плов классический'));
    await tester.pumpAndSettle();

    // The description also appears (truncated) on the home card underneath
    // the sheet, so match the sheet's own copy specifically.
    expect(find.text('Рис, мясо, морковь и специи.'), findsNWidgets(2));
    expect(find.text('Дополнительное мясо'), findsOneWidget);

    // Bump quantity to 2 and select the modifier.
    await tapAndSettle(tester, find.byIcon(Icons.add));
    await tapAndSettle(tester, find.byType(CheckboxListTile));
    await tapAndSettle(tester, find.text('Добавить в корзину'));

    // Switch to the cart tab.
    await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Плов классический'), findsOneWidget);
    expect(find.text('Дополнительное мясо'), findsOneWidget);
    expect(find.text('Товаров: 2'), findsOneWidget);

    // Increment then decrement twice back to zero, which removes the line.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Товаров: 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();

    expect(find.text('Корзина пуста'), findsOneWidget);
  });

  testWidgets('removing a cart line via the delete button', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Самса с бараниной'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Добавить в корзину'));

    await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Самса с бараниной'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Корзина пуста'), findsOneWidget);
  });

  testWidgets('switching restaurants via the location picker sheet', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();

    expect(find.text('ВЫБЕРИТЕ РЕСТОРАН'), findsOneWidget);
    expect(find.textContaining('Москва (Юг)'), findsOneWidget);

    await tester.tap(find.textContaining('Москва (Юг)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Москва (Юг)'), findsOneWidget);
  });
}
