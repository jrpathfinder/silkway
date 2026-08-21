import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/catalog.dart';
import 'package:silkway_app/features/cart/application/cart_notifier.dart';

const _plov = CatalogItem(
  id: 'plov-classic',
  categoryId: 'hot-dishes',
  name: 'Плов классический',
  description: 'Рис, мясо, морковь и специи.',
  priceRub: 590,
  isAvailable: true,
  modifiers: [CatalogModifier(id: 'extra-meat', name: 'Доп. мясо', priceRub: 180)],
);

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('addItem adds a new line', () {
    container.read(cartNotifierProvider.notifier).addItem('ca-moscow-1', _plov, quantity: 2);
    final cart = container.read(cartNotifierProvider);
    expect(cart.lines, hasLength(1));
    expect(cart.locationId, 'ca-moscow-1');
    expect(cart.itemCount, 2);
  });

  test('addItem merges quantity into an existing line with the same selection', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.addItem('ca-moscow-1', _plov, quantity: 2);

    final cart = container.read(cartNotifierProvider);
    expect(cart.lines, hasLength(1));
    expect(cart.lines.single.quantity, 3);
  });

  test('addItem keeps distinct lines for different modifier selections', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.addItem(
      'ca-moscow-1',
      _plov,
      quantity: 1,
      modifiers: const [CatalogModifier(id: 'extra-meat', name: 'Доп. мясо', priceRub: 180)],
    );

    expect(container.read(cartNotifierProvider).lines, hasLength(2));
  });

  test('updateQuantity changes the quantity of the given line', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.updateQuantity(0, 5);

    expect(container.read(cartNotifierProvider).lines.single.quantity, 5);
  });

  test('updateQuantity to zero or below removes the line', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.updateQuantity(0, 0);

    expect(container.read(cartNotifierProvider).lines, isEmpty);
  });

  test('removeLine drops the line at the given index', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.removeLine(0);

    expect(container.read(cartNotifierProvider).lines, isEmpty);
  });

  test('clear resets the cart to empty', () {
    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.addItem('ca-moscow-1', _plov, quantity: 1);
    notifier.clear();

    expect(container.read(cartNotifierProvider).isEmpty, isTrue);
  });
}
