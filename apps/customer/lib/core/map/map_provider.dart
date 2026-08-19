class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

class RoutePolyline {
  const RoutePolyline(this.points, this.etaMinutes);

  final List<GeoPoint> points;
  final int etaMinutes;
}

/// Client-only concern (no backend counterpart) — abstracts the map SDK so
/// the rest of the app never depends on a specific provider's API directly.
/// Real implementation will be Yandex MapKit; [MockMapProvider] is used
/// until API keys/billing are set up.
abstract class MapProvider {
  Future<GeoPoint> currentLocation();
  Future<RoutePolyline> routeBetween(GeoPoint from, GeoPoint to);
}
