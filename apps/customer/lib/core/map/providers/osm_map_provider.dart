import 'package:geolocator/geolocator.dart';

import '../map_provider.dart';

/// GPS через geolocator + OpenStreetMap-рендеринг (см. address_picker_screen)
/// — рабочая реализация без ключей API, в отличие от [YandexMapProvider].
///
/// [routeBetween] не реализован: он нужен для трекинга курьера, а не для
/// выбора адреса, и этой фиче не требуется — реализуем, когда понадобится.
class OsmMapProvider implements MapProvider {
  @override
  Future<GeoPoint> currentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
        throw StateError('Доступ к геолокации не предоставлен');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Доступ к геолокации заблокирован в настройках');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Службы геолокации выключены');
    }

    final position = await Geolocator.getCurrentPosition();
    return GeoPoint(position.latitude, position.longitude);
  }

  @override
  Future<RoutePolyline> routeBetween(GeoPoint from, GeoPoint to) {
    throw UnimplementedError('OsmMapProvider.routeBetween is not needed yet — only used for courier tracking.');
  }
}
