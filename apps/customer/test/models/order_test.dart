import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/order.dart';

void main() {
  group('OrderStatus.fromWire', () {
    const cases = {
      'PENDING_PAYMENT': OrderStatus.pendingPayment,
      'PAID': OrderStatus.paid,
      'ACCEPTED': OrderStatus.accepted,
      'PREPARING': OrderStatus.preparing,
      'READY_FOR_DELIVERY': OrderStatus.readyForDelivery,
      'IN_DELIVERY': OrderStatus.inDelivery,
      'DELIVERED': OrderStatus.delivered,
      'CANCELLED': OrderStatus.cancelled,
      'REFUNDED': OrderStatus.refunded,
    };

    cases.forEach((wire, status) {
      test('maps $wire to $status', () {
        expect(OrderStatus.fromWire(wire), status);
      });
    });

    test('throws on an unknown wire value', () {
      expect(() => OrderStatus.fromWire('SOMETHING_ELSE'), throwsArgumentError);
    });
  });

  group('OrderLine', () {
    test('fromJson defaults modifierIds to empty when absent', () {
      final line = OrderLine.fromJson({
        'itemId': 'plov-classic',
        'name': 'Плов классический',
        'quantity': 2,
        'unitPriceRub': 590,
      });
      expect(line.quantity, 2);
      expect(line.unitPriceRub, 590.0);
      expect(line.modifierIds, isEmpty);
    });

    test('fromJson parses modifierIds when present', () {
      final line = OrderLine.fromJson({
        'itemId': 'plov-classic',
        'name': 'Плов классический',
        'quantity': 1,
        'unitPriceRub': 770,
        'modifierIds': ['extra-meat'],
      });
      expect(line.modifierIds, ['extra-meat']);
    });
  });

  group('Order', () {
    test('fromJson parses nested lines, status, and dates', () {
      final order = Order.fromJson({
        'id': 'mock-1',
        'locationId': 'ca-moscow-1',
        'customerId': '+79990000000',
        'lines': [
          {'itemId': 'plov-classic', 'name': 'Плов классический', 'quantity': 1, 'unitPriceRub': 590},
        ],
        'totalRub': 590,
        'status': 'PAID',
        'createdAt': '2026-08-19T12:00:00.000Z',
      });
      expect(order.id, 'mock-1');
      expect(order.lines, hasLength(1));
      expect(order.status, OrderStatus.paid);
      expect(order.createdAt, DateTime.parse('2026-08-19T12:00:00.000Z'));
      expect(order.paymentId, isNull);
    });

    test('fromJson parses an optional paymentId when present', () {
      final order = Order.fromJson({
        'id': 'mock-1',
        'locationId': 'ca-moscow-1',
        'customerId': '+79990000000',
        'lines': const [],
        'totalRub': 0,
        'status': 'PENDING_PAYMENT',
        'createdAt': '2026-08-19T12:00:00.000Z',
        'paymentId': 'pay-1',
      });
      expect(order.paymentId, 'pay-1');
    });
  });
}
