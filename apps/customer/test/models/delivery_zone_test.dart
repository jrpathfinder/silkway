import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/delivery_zone.dart';

void main() {
  group('MoscowDeliveryZone', () {
    test('contains central Moscow', () {
      expect(MoscowDeliveryZone.contains(55.7539, 37.6208), isTrue);
    });

    test('contains VDNKh, well inside the ring', () {
      expect(MoscowDeliveryZone.contains(55.8296, 37.6339), isTrue);
    });

    test('rejects Zelenograd — a separate Moscow exclave outside MKAD', () {
      expect(MoscowDeliveryZone.contains(55.9833, 37.2166), isFalse);
    });

    test('rejects the three main Moscow airports — all outside MKAD', () {
      expect(MoscowDeliveryZone.contains(55.5915, 37.2615), isFalse); // Внуково
      expect(MoscowDeliveryZone.contains(55.9726, 37.4146), isFalse); // Шереметьево
      expect(MoscowDeliveryZone.contains(55.4103, 37.9062), isFalse); // Домодедово
    });

    test('rejects New Moscow (added in the 2012 expansion, well outside MKAD)', () {
      expect(MoscowDeliveryZone.contains(55.5747, 37.4816), isFalse);
    });

    test('rejects Saint Petersburg', () {
      expect(MoscowDeliveryZone.contains(59.9311, 30.3609), isFalse);
    });

    test('ring has enough points to look like MKAD, not a rectangle', () {
      expect(MoscowDeliveryZone.ringPoints.length, greaterThan(10));
    });
  });
}
