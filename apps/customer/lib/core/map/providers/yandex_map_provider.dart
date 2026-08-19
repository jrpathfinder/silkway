import '../map_provider.dart';

/// Real Yandex MapKit implementation — not wired up yet (needs API
/// keys/billing). Kept as the concrete slot [MapProvider] switches to once
/// ready, matching the other ports' mock-now/http-stub-for-later pattern.
class YandexMapProvider implements MapProvider {
  @override
  Future<GeoPoint> currentLocation() {
    throw UnimplementedError('YandexMapProvider is not wired up yet — needs Yandex MapKit API keys.');
  }

  @override
  Future<RoutePolyline> routeBetween(GeoPoint from, GeoPoint to) {
    throw UnimplementedError('YandexMapProvider is not wired up yet — needs Yandex MapKit API keys.');
  }
}
