import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/delivery.dart';
import 'package:silkway_app/core/models/notification.dart';

void main() {
  test('DeliveryQuote exposes its constructor fields', () {
    const quote = DeliveryQuote(zoneId: 'moscow-center', priceRub: 199, minOrderRub: 800, etaMinutes: 40);
    expect(quote.zoneId, 'moscow-center');
    expect(quote.priceRub, 199);
    expect(quote.minOrderRub, 800);
    expect(quote.etaMinutes, 40);
  });

  test('DeliveryTrackingPoint exposes its constructor fields', () {
    const point = DeliveryTrackingPoint(lat: 55.75, lng: 37.61, label: 'Курьер в пути');
    expect(point.lat, 55.75);
    expect(point.lng, 37.61);
    expect(point.label, 'Курьер в пути');
  });

  test('AppNotification defaults read to false', () {
    final notification = AppNotification(id: 'n1', title: 'Заказ принят', body: 'Ваш заказ готовится', createdAt: DateTime(2026, 8, 19));
    expect(notification.read, isFalse);
  });

  test('AppNotification accepts an explicit read value', () {
    final notification = AppNotification(
      id: 'n1',
      title: 'Заказ принят',
      body: 'Ваш заказ готовится',
      createdAt: DateTime(2026, 8, 19),
      read: true,
    );
    expect(notification.read, isTrue);
  });
}
