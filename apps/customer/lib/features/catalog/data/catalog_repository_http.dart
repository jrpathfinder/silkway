import '../../../core/models/catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/catalog_repository.dart';

/// Каталог из бэкенда. Реализован полностью.
class CatalogRepositoryHttp implements CatalogRepository {
  CatalogRepositoryHttp(this._client);

  final ApiClient _client;

  @override
  Future<CatalogResponse> getForLocation(String locationId) async {
    final res = await _client.dio.get('/v1/locations/$locationId/catalog');
    return CatalogResponse.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
