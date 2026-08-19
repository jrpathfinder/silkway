import '../../../core/models/catalog.dart';
import '../../../core/ports/catalog_repository.dart';

/// Fixture data copied 1:1 from the backend's own dev fallback
/// (CatalogService.fallbackCatalog in apps/api) — same ids/names/prices — so
/// switching USE_MOCKS on/off against the real dev backend never produces
/// visibly different data.
class CatalogRepositoryMock implements CatalogRepository {
  @override
  Future<CatalogResponse> getForLocation(String locationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return CatalogResponse(
      locationId: locationId,
      currency: 'RUB',
      categories: const [
        CatalogCategory(id: 'hot-dishes', name: 'Горячие блюда', sortOrder: 1),
        CatalogCategory(id: 'snacks', name: 'Закуски', sortOrder: 2),
      ],
      items: const [
        CatalogItem(
          id: 'plov-classic',
          categoryId: 'hot-dishes',
          name: 'Плов классический',
          description: 'Рис, мясо, морковь и специи.',
          priceRub: 590,
          isAvailable: true,
          modifiers: [CatalogModifier(id: 'extra-meat', name: 'Дополнительное мясо', priceRub: 180)],
        ),
        CatalogItem(
          id: 'samsa-lamb',
          categoryId: 'snacks',
          name: 'Самса с бараниной',
          description: 'Слоеное тесто и сочная начинка.',
          priceRub: 220,
          isAvailable: true,
          modifiers: [],
        ),
      ],
    );
  }
}
