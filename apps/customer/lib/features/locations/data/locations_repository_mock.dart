import '../../../core/models/location.dart';
import '../../../core/ports/locations_repository.dart';

/// The real backend currently seeds only one location (`ca-moscow-1`, see
/// locations.service.ts). A second mock location is added here purely to
/// make the location-picker sheet demoable before a second real location
/// exists — expect the list to shrink to one when USE_MOCKS=false today.
class LocationsRepositoryMock implements LocationsRepository {
  static const _locations = [
    RestaurantLocation(
      id: 'ca-moscow-1',
      cityId: 'moscow',
      name: 'Central Asia Restaurant — Москва (Центр)',
      address: 'Москва, адрес будет указан при запуске',
      timezone: 'Europe/Moscow',
      isActive: true,
    ),
    RestaurantLocation(
      id: 'ca-moscow-2',
      cityId: 'moscow',
      name: 'Central Asia Restaurant — Москва (Юг)',
      address: 'Москва, адрес будет указан при запуске',
      timezone: 'Europe/Moscow',
      isActive: true,
    ),
  ];

  @override
  Future<List<RestaurantLocation>> listActive() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _locations.where((l) => l.isActive).toList();
  }

  @override
  Future<RestaurantLocation?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final location in _locations) {
      if (location.id == id) return location;
    }
    return null;
  }
}
