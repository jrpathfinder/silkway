import '../models/catalog.dart';

abstract class CatalogRepository {
  Future<CatalogResponse> getForLocation(String locationId);
}
