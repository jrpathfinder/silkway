/// Меню ресторана: категории, блюда и модификаторы.
///
/// Цены приходят в рублях (`priceRub`) — в Postgres они хранятся в копейках
/// целым числом, конвертация происходит на бэкенде.
class CatalogCategory {
  const CatalogCategory({required this.id, required this.name, required this.sortOrder});

  final String id;
  final String name;
  final int sortOrder;

  /// The backend leaks the raw SQL column name `sort_order` (snake_case)
  /// instead of camelCasing it (see CatalogService.getForLocation) — accept
  /// both keys defensively rather than assuming full camelCase consistency.
  factory CatalogCategory.fromJson(Map<String, dynamic> json) => CatalogCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        sortOrder: (json['sort_order'] ?? json['sortOrder'] ?? 0) as int,
      );
}

class CatalogModifier {
  const CatalogModifier({required this.id, required this.name, required this.priceRub});

  final String id;
  final String name;
  final double priceRub;

  factory CatalogModifier.fromJson(Map<String, dynamic> json) => CatalogModifier(
        id: json['id'] as String,
        name: json['name'] as String,
        priceRub: (json['priceRub'] as num).toDouble(),
      );
}

/// БЖУ на 100 г — часть реального контракта Vendor API Яндекс Еды
/// (`nutrients` в ответе `partner.menu.get`), которую мы пока нигде не
/// потребляли.
class CatalogNutritionFacts {
  const CatalogNutritionFacts({
    required this.caloriesKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  final double caloriesKcal;
  final double proteinG;
  final double fatG;
  final double carbsG;

  factory CatalogNutritionFacts.fromJson(Map<String, dynamic> json) => CatalogNutritionFacts(
        caloriesKcal: (json['caloriesKcal'] as num).toDouble(),
        proteinG: (json['proteinG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
      );
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceRub,
    required this.isAvailable,
    required this.modifiers,
    this.imageUrl,
    this.weightLabel,
    this.originalPriceRub,
    this.ratingPercent,
    this.ratingCount,
    this.composition,
    this.nutritionPer100g,
    this.modifierGroupLabel,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double priceRub;
  final bool isAvailable;
  final List<CatalogModifier> modifiers;

  /// Not part of the backend contract yet (CatalogService has no image
  /// field) — a bundled asset path (e.g. "assets/branding/dishes/plov.png")
  /// today from CatalogRepositoryMock, or a remote URL once the backend adds
  /// one. See DishImage for how the two are told apart.
  final String? imageUrl;

  /// Вес/объём порции для подписи рядом с названием ("300 г") — отдельно от
  /// [description], у которой в реальных данных это маркетинговый текст, а
  /// не характеристика порции.
  final String? weightLabel;

  /// Цена до скидки. `null`, когда скидки нет — тогда [priceRub] показывается
  /// как единственная цена, без зачёркнутой.
  final double? originalPriceRub;

  /// Рейтинг блюда с витрины (0–100) и число оценок, на которых он основан.
  /// Оба или ни одного — раздельно не имеют смысла.
  final int? ratingPercent;
  final int? ratingCount;

  /// Состав блюда — отдельная секция карточки, не часть [description].
  final String? composition;

  final CatalogNutritionFacts? nutritionPer100g;

  /// Заголовок над списком [modifiers] в карточке блюда (например, «К
  /// плову»). `null` — виджет подставляет свой дефолт.
  final String? modifierGroupLabel;

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        priceRub: (json['priceRub'] as num).toDouble(),
        isAvailable: json['isAvailable'] as bool,
        modifiers: (json['modifiers'] as List<dynamic>? ?? const [])
            .map((m) => CatalogModifier.fromJson(m as Map<String, dynamic>))
            .toList(),
        imageUrl: json['imageUrl'] as String?,
        weightLabel: json['weightLabel'] as String?,
        originalPriceRub: (json['originalPriceRub'] as num?)?.toDouble(),
        ratingPercent: json['ratingPercent'] as int?,
        ratingCount: json['ratingCount'] as int?,
        composition: json['composition'] as String?,
        nutritionPer100g: json['nutritionPer100g'] == null
            ? null
            : CatalogNutritionFacts.fromJson(json['nutritionPer100g'] as Map<String, dynamic>),
        modifierGroupLabel: json['modifierGroupLabel'] as String?,
      );
}

class CatalogResponse {
  const CatalogResponse({
    required this.locationId,
    required this.currency,
    required this.categories,
    required this.items,
  });

  final String locationId;
  final String currency;
  final List<CatalogCategory> categories;
  final List<CatalogItem> items;

  factory CatalogResponse.fromJson(Map<String, dynamic> json) => CatalogResponse(
        locationId: json['locationId'] as String,
        currency: json['currency'] as String,
        categories: (json['categories'] as List<dynamic>)
            .map((c) => CatalogCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
        items: (json['items'] as List<dynamic>)
            .map((i) => CatalogItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  List<CatalogItem> get availableItems => items.where((item) => item.isAvailable).toList();

  CatalogItem itemById(String id) => items.firstWhere((item) => item.id == id);
}
