import '../models/catalog.dart';

/// Контракт доступа к каталогу.
///
/// Домен зависит от этого интерфейса, а не от конкретной реализации: в
/// зависимости от Env.useMocks подставляется мок или HTTP-версия
/// (см. catalog_providers.dart).
abstract class CatalogRepository {
  Future<CatalogResponse> getForLocation(String locationId);
}
