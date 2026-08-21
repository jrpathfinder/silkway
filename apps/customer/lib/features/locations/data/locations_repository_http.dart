import '../../../core/models/location.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/locations_repository.dart';

/// Рестораны из бэкенда. Реализован полностью.
class LocationsRepositoryHttp implements LocationsRepository {
  LocationsRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<List<RestaurantLocation>> listActive() async {
    final res = await _client.dio.get('/v1/locations');
    final data = res.data['data'] as List<dynamic>;
    return data.map((l) => RestaurantLocation.fromJson(l as Map<String, dynamic>)).toList();
  }

  @override
  Future<RestaurantLocation?> getById(String id) async {
    final res = await _client.dio.get('/v1/locations/$id');
    final data = res.data['data'];
    return data == null ? null : RestaurantLocation.fromJson(data as Map<String, dynamic>);
  }
}
