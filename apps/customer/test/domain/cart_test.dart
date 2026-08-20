import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/catalog.dart';
import 'package:silkway_app/features/cart/domain/cart.dart';

const _plov = CatalogItem(
  id: 'plov-classic',
  categoryId: 'hot-dishes',
  name: 'Плов классический',
  description: 'Рис, мясо, морковь и специи.',
  priceRub: 590,
  isAvailable: true,
  modifiers: [CatalogModifier(id: 'extra-meat', name: 'Доп. мясо', priceRub: 180)],
);

const _samsa = CatalogItem(
  id: 'samsa-lamb',
  categoryId: 'snacks',
  name: 'Самса с бараниной',
  description: 'Слоеное тесто и сочная начинка.',
  priceRub: 220,
  isAvailable: true,
  modifiers: [],
);

void main() {
  group('CartLine', () {
    test('unitPriceRub adds selected modifiers to the item price', () {
      const line = CartLine(item: _plov, quantity: 1, selectedModifiers: [CatalogModifier(id: 'extra-meat', name: 'Доп. мясо', priceRub: 180)]);
      expect(line.unitPriceRub, 770);
    });

    test('totalRub multiplies unitPriceRub by quantity', () {
      const line = CartLine(item: _samsa, quantity: 3, selectedModifiers: []);
      expect(line.totalRub, 660);
    });

    test('sameSelectionAs is true for identical item+modifier selection regardless of order', () {
      const a = CartLine(
        item: _plov,
        quantity: 1,
        selectedModifiers: [CatalogModifier(id: 'x', name: 'X', priceRub: 1), CatalogModifier(id: 'y', name: 'Y', priceRub: 1)],
      );
      const b = CartLine(
        item: _plov,
        quantity: 5,
        selectedModifiers: [CatalogModifier(id: 'y', name: 'Y', priceRub: 1), CatalogModifier(id: 'x', name: 'X', priceRub: 1)],
      );
      expect(a.sameSelectionAs(b), isTrue);
    });

    test('sameSelectionAs is false for a different item', () {
      const a = CartLine(item: _plov, quantity: 1, selectedModifiers: []);
      const b = CartLine(item: _samsa, quantity: 1, selectedModifiers: []);
      expect(a.sameSelectionAs(b), isFalse);
    });

    test('sameSelectionAs is false for a different modifier selection', () {
      const a = CartLine(item: _plov, quantity: 1, selectedModifiers: []);
      const b = CartLine(item: _plov, quantity: 1, selectedModifiers: [CatalogModifier(id: 'extra-meat', name: 'Доп. мясо', priceRub: 180)]);
      expect(a.sameSelectionAs(b), isFalse);
    });

    test('copyWith replaces only the quantity', () {
      const line = CartLine(item: _plov, quantity: 1, selectedModifiers: []);
      final updated = line.copyWith(quantity: 4);
      expect(updated.quantity, 4);
      expect(updated.item, _plov);
    });

    test('signature is deterministic and sorted by modifier id', () {
      const line = CartLine(
        item: _plov,
        quantity: 2,
        selectedModifiers: [CatalogModifier(id: 'z', name: 'Z', priceRub: 1), CatalogModifier(id: 'a', name: 'A', priceRub: 1)],
      );
      expect(line.signature, 'plov-classic:2:a,z');
    });
  });

  group('Cart', () {
    test('itemCount sums quantities across lines', () {
      const cart = Cart(lines: [
        CartLine(item: _plov, quantity: 2, selectedModifiers: []),
        CartLine(item: _samsa, quantity: 3, selectedModifiers: []),
      ]);
      expect(cart.itemCount, 5);
    });

    test('totalRub sums each line total', () {
      const cart = Cart(lines: [
        CartLine(item: _plov, quantity: 1, selectedModifiers: []),
        CartLine(item: _samsa, quantity: 1, selectedModifiers: []),
      ]);
      expect(cart.totalRub, 810);
    });

    test('isEmpty reflects whether there are any lines', () {
      expect(const Cart().isEmpty, isTrue);
      expect(const Cart(lines: [CartLine(item: _plov, quantity: 1, selectedModifiers: [])]).isEmpty, isFalse);
    });

    test('fingerprint is stable regardless of line order', () {
      const cartA = Cart(lines: [
        CartLine(item: _plov, quantity: 1, selectedModifiers: []),
        CartLine(item: _samsa, quantity: 1, selectedModifiers: []),
      ]);
      const cartB = Cart(lines: [
        CartLine(item: _samsa, quantity: 1, selectedModifiers: []),
        CartLine(item: _plov, quantity: 1, selectedModifiers: []),
      ]);
      expect(cartA.fingerprint, cartB.fingerprint);
    });

    test('copyWith replaces locationId and lines independently', () {
      const cart = Cart(locationId: 'ca-moscow-1', lines: []);
      final updated = cart.copyWith(lines: [const CartLine(item: _plov, quantity: 1, selectedModifiers: [])]);
      expect(updated.locationId, 'ca-moscow-1');
      expect(updated.lines, hasLength(1));
    });
  });
}
