import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/delivery_zone.dart';

void main() {
  group('MoscowDeliveryZone', () {
    test('contains central Moscow', () {
      expect(MoscowDeliveryZone.contains(55.751244, 37.618423), isTrue);
    });

    test('rejects Saint Petersburg', () {
      expect(MoscowDeliveryZone.contains(59.9311, 30.3609), isFalse);
    });

    test('rejects points just outside each edge of the box', () {
      expect(MoscowDeliveryZone.contains(MoscowDeliveryZone.minLat - 0.01, 37.6), isFalse);
      expect(MoscowDeliveryZone.contains(MoscowDeliveryZone.maxLat + 0.01, 37.6), isFalse);
      expect(MoscowDeliveryZone.contains(55.7, MoscowDeliveryZone.minLng - 0.01), isFalse);
      expect(MoscowDeliveryZone.contains(55.7, MoscowDeliveryZone.maxLng + 0.01), isFalse);
    });

    test('includes the box edges themselves', () {
      expect(MoscowDeliveryZone.contains(MoscowDeliveryZone.minLat, MoscowDeliveryZone.minLng), isTrue);
      expect(MoscowDeliveryZone.contains(MoscowDeliveryZone.maxLat, MoscowDeliveryZone.maxLng), isTrue);
    });
  });
}
