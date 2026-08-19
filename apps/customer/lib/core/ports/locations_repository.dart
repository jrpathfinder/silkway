import '../models/location.dart';

abstract class LocationsRepository {
  Future<List<RestaurantLocation>> listActive();
  Future<RestaurantLocation?> getById(String id);
}
