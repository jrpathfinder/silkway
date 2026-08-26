import '../../../core/models/catalog.dart';
import '../../../core/ports/catalog_repository.dart';
import 'menu_placeholder_extra.dart';
import 'menu_video_import.dart';

/// Started as a 1:1 copy of the backend's own dev fallback
/// (CatalogService.fallbackCatalog in apps/api), plus temporary extensions
/// appended on top: [videoImportedHotDishesTail] (real hot-dishes items
/// transcribed from the restaurant's own Yandex Eda listing) and
/// [placeholderExtraCategories] / [placeholderExtraItems] (entirely invented
/// items for the categories that haven't been transcribed at all, so the
/// menu has enough volume to browse across every section).
///
/// `plov-classic` has also since been enriched with real data pulled from
/// the live Yandex Eda listing (name, discount price, rating, composition,
/// nutrition, real add-ons) — its `priceRub`/`modifiers` no longer match
/// apps/api's fallback. That backend fixture is left alone deliberately:
/// it feeds orders.service.spec.ts's price-recompute assertions, and this
/// enrichment is purely a Flutter-side display concern (fields like
/// `weightLabel`/`nutritionPer100g` don't exist in the backend's
/// CatalogItem type). All of this is temporary and gets replaced once the
/// real importer (tools/import-yandex-menu.mjs) is wired up.
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
          name: 'Плов по-ташкентски',
          description:
              'Хотите насладиться настоящим узбекским блюдом? Попробуйте наш плов '
              'по-ташкентски! Это горячее блюдо приготовлено из нежной говядины, '
              'рассыпчатого риса лазер и питательных ингредиентов: нута, тмина, лука, '
              'моркови, зиры и ароматных специй. А пикантности плову добавляют '
              'перепелиные яйца и маринованный перец.',
          priceRub: 335.40,
          originalPriceRub: 559,
          isAvailable: true,
          weightLabel: '300 г',
          ratingPercent: 87,
          ratingCount: 47,
          composition: 'говядина, рис лазер, нут, тмин, лук, морковь, зира, яйца перепелиные, '
              'перец маринованный, специи',
          nutritionPer100g: CatalogNutritionFacts(caloriesKcal: 149, proteinG: 12, fatG: 10, carbsG: 6),
          modifierGroupLabel: 'К плову',
          modifiers: [
            CatalogModifier(id: 'tandoor-side', name: 'Тандырная лепешка', priceRub: 59.40),
            CatalogModifier(id: 'achik-chuchuk-side', name: 'Салат Аччик-Чучук', priceRub: 239.40),
          ],
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
