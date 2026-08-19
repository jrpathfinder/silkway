import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/catalog.dart';
import '../../../../core/ports/catalog_repository.dart';
import '../../../../core/providers.dart';
import '../../data/catalog_repository_http.dart';
import '../../data/catalog_repository_mock.dart';

/// Reference implementation of the mock/real repository switch — replicate
/// this three-part shape (repository interface + two implementations + this
/// provider file) for every other backend integration.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final env = ref.watch(envProvider);
  return env.useMocks ? CatalogRepositoryMock() : CatalogRepositoryHttp(ref.watch(apiClientProvider));
});

final catalogProvider = FutureProvider.family<CatalogResponse, String>((ref, locationId) {
  return ref.watch(catalogRepositoryProvider).getForLocation(locationId);
});
