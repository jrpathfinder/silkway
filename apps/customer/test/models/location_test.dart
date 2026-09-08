import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/location.dart';

void main() {
  test('RestaurantLocation.fromJson parses all fields', () {
    final location = RestaurantLocation.fromJson({
      'id': 'ca-moscow-1',
      'cityId': 'moscow',
      'name': 'Шелковый путь — Москва',
      'address': 'Москва, адрес будет указан при запуске',
      'timezone': 'Europe/Moscow',
      'isActive': true,
    });
    expect(location.id, 'ca-moscow-1');
    expect(location.cityId, 'moscow');
    expect(location.timezone, 'Europe/Moscow');
    expect(location.isActive, isTrue);
  });
}
