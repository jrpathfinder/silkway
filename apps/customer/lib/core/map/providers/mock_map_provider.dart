import '../map_provider.dart';

/// Заглушка карт: ничего не рисует, нужна чтобы собрать приложение без
/// ключей Яндекс MapKit.
class MockMapProvider implements MapProvider {
  @override
  Future<GeoPoint> currentLocation() async => const GeoPoint(55.751244, 37.618423); // central Moscow

  @override
  Future<RoutePolyline> routeBetween(GeoPoint from, GeoPoint to) async {
    // Straight-line stub — good enough to prove tracking/navigation screens
    // before Yandex MapKit is wired in.
    return RoutePolyline([from, to], 12);
  }
}
