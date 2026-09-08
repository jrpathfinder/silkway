import '../../../core/models/location.dart';
import '../../../core/ports/locations_repository.dart';

/// Mirrors the real backend, which seeds exactly this one location (see
/// locations.service.ts).
class LocationsRepositoryMock implements LocationsRepository {
  static const _locations = [
    RestaurantLocation(
      id: 'ca-moscow-1',
      cityId: 'moscow',
      name: 'Шелковый путь — Москва',
      address: 'Москва, ул. Народного Ополчения, 20к1',
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
