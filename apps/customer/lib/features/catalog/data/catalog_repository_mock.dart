import '../../../core/models/catalog.dart';
import '../../../core/ports/catalog_repository.dart';
import 'menu_placeholder_extra.dart';
import 'menu_video_import.dart';

/// Fixture data copied 1:1 from the backend's own dev fallback
/// (CatalogService.fallbackCatalog in apps/api) — same ids/names/prices — so
/// switching USE_MOCKS on/off against the real dev backend never produces
/// visibly different data, PLUS two temporary extensions appended on top:
/// [videoImportedHotDishesTail] (real hot-dishes items transcribed from the
/// restaurant's own Yandex Eda listing) and [placeholderExtraCategories] /
/// [placeholderExtraItems] (entirely invented items for the categories that
/// haven't been transcribed at all, so the menu has enough volume to browse
/// across every section). Both extensions intentionally diverge from the
/// backend fallback — they're temporary and get replaced once the real
/// importer (tools/import-yandex-menu.mjs) is wired up.
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
        ...placeholderExtraCategories,
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
          imageUrl: 'assets/branding/dishes/plov.png',
        ),
        CatalogItem(
          id: 'samsa-lamb',
          categoryId: 'snacks',
          name: 'Самса с бараниной',
          description: 'Слоеное тесто и сочная начинка.',
          priceRub: 220,
          isAvailable: true,
          modifiers: [],
          imageUrl: 'assets/branding/dishes/samsa.png',
        ),
        ...videoImportedHotDishesTail,
        ...placeholderExtraItems,
      ],
    );
  }
}
