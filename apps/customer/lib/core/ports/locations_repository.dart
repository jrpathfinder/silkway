import '../models/location.dart';

/// Контракт доступа к списку ресторанов.
abstract class LocationsRepository {
  Future<List<RestaurantLocation>> listActive();
  Future<RestaurantLocation?> getById(String id);
}
