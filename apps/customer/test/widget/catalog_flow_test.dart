import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/catalog/presentation/home_screen.dart';

import '../helpers/pump_helpers.dart';

Future<void> _pumpApp(WidgetTester tester) => pumpAppPastSplash(tester);

/// Меню теперь разбито на разделы по категориям, и списки внутри ленивые:
/// блюдо из второго раздела просто не существует в дереве, пока до него не
/// доскроллили. Поэтому ищем прокруткой, а не голым find.
Future<void> _scrollToDish(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text(name),
    200,
    scrollable: find.descendant(
      of: find.byKey(HomeScreen.menuListKey),
      matching: find.byType(Scrollable),
    ).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('browsing, adding to cart, and editing the cart line', (tester) async {
    await _pumpApp(tester);

    // Меню показывает каталог из моков, разложенный по разделам.
    // Название категории встречается дважды: чип фильтра и заголовок раздела.
    expect(find.text('Всё'), findsOneWidget);
    expect(find.text('Горячие блюда'), findsNWidgets(2));
    expect(find.text('Плов классический'), findsOneWidget);

    // Открываем карточку блюда. Второй раздел проверяется отдельным тестом:
    // прокрутка к нему уводит «Плов» за пределы экрана.
    //
    // ensureVisible обязателен: карточка с фото высокая, и в тестовом
    // вьюпорте название может оказаться ниже видимой области — тап по
    // невидимой точке не засчитывается.
    await tester.ensureVisible(find.text('Плов классический'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Плов классический'));
    await tester.pumpAndSettle();

    // Признак того, что шторка открылась, — модификатор: он есть только в
    // карточке блюда. Описание встречается и в списке, и в шторке, поэтому
    // по нему проверять ненадёжно.
    expect(find.text('Дополнительное мясо'), findsOneWidget);
    expect(find.textContaining('Рис, мясо, морковь'), findsAtLeastNWidgets(1));

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

    await _scrollToDish(tester, 'Самса с бараниной');
    await tester.ensureVisible(find.text('Самса с бараниной'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(HomeScreen.locationPickerKey));
    await tester.pumpAndSettle();

    expect(find.text('ВЫБЕРИТЕ РЕСТОРАН'), findsOneWidget);
    expect(find.textContaining('Москва (Юг)'), findsOneWidget);

    await tester.tap(find.textContaining('Москва (Юг)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Москва (Юг)'), findsOneWidget);
  });
}
