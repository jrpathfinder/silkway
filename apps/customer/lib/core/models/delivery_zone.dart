/// Реальная граница МКАД — не полная административная Москва (та включает
/// Новую Москву, добавленную в 2012-м, далеко на юго-запад), а именно кольцо.
///
/// Точки получены из OSM (маршрут МКАД, relation 2094222 в Overpass),
/// упрощены алгоритмом Дугласа — Пекера (~2660 узлов дороги → 25 точек) —
/// этого достаточно, чтобы контур на карте читался как МКАД и проверка
/// "внутри/снаружи" была геометрически верной, но не тащить в бандл тысячи
/// точек дорожной геометрии ради проверки зоны доставки.
///
/// ВАЖНО: тот же список точек продублирован на бэкенде
/// (apps/api/src/modules/orders/orders.service.ts, MOSCOW_DELIVERY_ZONE) —
/// осознанное дублирование через границу Dart/TypeScript, как и остальные
/// конвенции в этом кодбейзе; при изменении обновляй оба места.
abstract final class MoscowDeliveryZone {
  static const List<(double, double)> _ring = [
    (55.75029, 37.36881),
    (55.74098, 37.37171),
    (55.71007, 37.38823),
    (55.66014, 37.43436),
    (55.60019, 37.50455),
    (55.59435, 37.51673),
    (55.57687, 37.58977),
    (55.57184, 37.6666),
    (55.57428, 37.68387),
    (55.60115, 37.75204),
    (55.62193, 37.79082),
    (55.64916, 37.83306),
    (55.65352, 37.83755),
    (55.65889, 37.83977),
    (55.77145, 37.84349),
    (55.82199, 37.8371),
    (55.83127, 37.82568),
    (55.88901, 37.71321),
    (55.89385, 37.70017),
    (55.911, 37.57288),
    (55.90587, 37.52902),
    (55.87174, 37.41367),
    (55.86274, 37.40028),
    (55.84883, 37.39203),
    (55.7847, 37.36997),
  ];

  /// Точки кольца как (lat, lng) — без зависимости на конкретный SDK карты
  /// (тот же принцип, что и у GeoPoint в core/map/map_provider.dart);
  /// экран сам оборачивает их в LatLng для отрисовки.
  static List<(double, double)> get ringPoints => _ring;

  /// Грубый прямоугольник вокруг кольца — быстрая отбраковка явно далёких
  /// точек перед точным (и более дорогим) point-in-polygon.
  static final double _minLat = _ring.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
  static final double _maxLat = _ring.map((p) => p.$1).reduce((a, b) => a > b ? a : b);
  static final double _minLng = _ring.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
  static final double _maxLng = _ring.map((p) => p.$2).reduce((a, b) => a > b ? a : b);

  /// Ray casting — стандартный алгоритм проверки точки внутри многоугольника.
  static bool contains(double lat, double lng) {
    if (lat < _minLat || lat > _maxLat || lng < _minLng || lng > _maxLng) return false;

    var inside = false;
    for (var i = 0, j = _ring.length - 1; i < _ring.length; j = i++) {
      final (latI, lngI) = _ring[i];
      final (latJ, lngJ) = _ring[j];
      final intersects = (latI > lat) != (latJ > lat) && lng < (lngJ - lngI) * (lat - latI) / (latJ - latI) + lngI;
      if (intersects) inside = !inside;
    }
    return inside;
  }
}
