import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/catalog.dart';

void main() {
  group('CatalogCategory', () {
    test('fromJson reads camelCase sortOrder', () {
      final category = CatalogCategory.fromJson({'id': 'hot', 'name': 'Горячие блюда', 'sortOrder': 1});
      expect(category.id, 'hot');
      expect(category.name, 'Горячие блюда');
      expect(category.sortOrder, 1);
    });

    test('fromJson falls back to snake_case sort_order', () {
      final category = CatalogCategory.fromJson({'id': 'hot', 'name': 'Горячие блюда', 'sort_order': 2});
      expect(category.sortOrder, 2);
    });

    test('fromJson defaults sortOrder to 0 when neither key is present', () {
      final category = CatalogCategory.fromJson({'id': 'hot', 'name': 'Горячие блюда'});
      expect(category.sortOrder, 0);
    });
  });

  group('CatalogModifier', () {
    test('fromJson parses priceRub from a num', () {
      final modifier = CatalogModifier.fromJson({'id': 'extra-meat', 'name': 'Доп. мясо', 'priceRub': 180});
      expect(modifier.id, 'extra-meat');
      expect(modifier.priceRub, 180.0);
    });
  });

  group('CatalogItem', () {
    test('fromJson parses modifiers and optional imageUrl', () {
      final item = CatalogItem.fromJson({
        'id': 'plov-classic',
        'categoryId': 'hot-dishes',
        'name': 'Плов классический',
        'description': 'Рис, мясо, морковь и специи.',
        'priceRub': 590,
        'isAvailable': true,
        'modifiers': [
          {'id': 'extra-meat', 'name': 'Доп. мясо', 'priceRub': 180},
        ],
        'imageUrl': 'assets/branding/dishes/plov.png',
      });
      expect(item.id, 'plov-classic');
      expect(item.priceRub, 590.0);
      expect(item.modifiers, hasLength(1));
      expect(item.modifiers.first.name, 'Доп. мясо');
      expect(item.imageUrl, 'assets/branding/dishes/plov.png');
    });

    test('fromJson defaults modifiers to empty and imageUrl to null when absent', () {
      final item = CatalogItem.fromJson({
        'id': 'samsa-lamb',
        'categoryId': 'snacks',
        'name': 'Самса с бараниной',
        'description': 'Слоеное тесто и сочная начинка.',
        'priceRub': 220,
        'isAvailable': true,
      });
      expect(item.modifiers, isEmpty);
      expect(item.imageUrl, isNull);
    });
  });

  group('CatalogResponse', () {
    final json = {
      'locationId': 'ca-moscow-1',
      'currency': 'RUB',
      'categories': [
        {'id': 'hot', 'name': 'Горячие блюда', 'sortOrder': 1},
      ],
      'items': [
        {
          'id': 'plov-classic',
          'categoryId': 'hot',
          'name': 'Плов классический',
          'description': 'Рис, мясо, морковь и специи.',
          'priceRub': 590,
          'isAvailable': true,
        },
        {
          'id': 'sold-out-dish',
          'categoryId': 'hot',
          'name': 'Нет в наличии',
          'description': '-',
          'priceRub': 100,
          'isAvailable': false,
        },
      ],
    };

    test('fromJson parses nested categories and items', () {
      final response = CatalogResponse.fromJson(json);
      expect(response.locationId, 'ca-moscow-1');
      expect(response.categories, hasLength(1));
      expect(response.items, hasLength(2));
    });

    test('availableItems filters out unavailable items', () {
      final response = CatalogResponse.fromJson(json);
      expect(response.availableItems, hasLength(1));
      expect(response.availableItems.single.id, 'plov-classic');
    });

    test('itemById finds an item by id', () {
      final response = CatalogResponse.fromJson(json);
      expect(response.itemById('sold-out-dish').name, 'Нет в наличии');
    });
  });
}
