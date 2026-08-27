/// Грубый прямоугольник вокруг Москвы — не настоящая административная
/// граница и не полигон зоны доставки, а быстрая приближённая проверка
/// "похоже на Москву или нет" для MVP с одним рестораном.
///
/// Реальные зоны доставки (несколько зон, точные границы, разная стоимость
/// и минимальный заказ по зоне) — предмет отдельной задачи (SIL-10), здесь
/// этого нет. Значения ниже подобраны так, чтобы покрыть Москву в пределах
/// МКАД с небольшим запасом на ближайшее Подмосковье.
///
/// ВАЖНО: те же границы продублированы на бэкенде
/// (apps/api/src/modules/orders/orders.service.ts, MOSCOW_DELIVERY_ZONE) —
/// это осознанное дублирование через границу Dart/TypeScript, а не общий
/// код; при изменении обновляй оба места.
abstract final class MoscowDeliveryZone {
  static const double minLat = 55.48;
  static const double maxLat = 55.95;
  static const double minLng = 37.25;
  static const double maxLng = 37.95;

  static bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}
