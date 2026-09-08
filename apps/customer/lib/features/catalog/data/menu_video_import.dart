import '../../../core/models/catalog.dart';

/// Черновой снимок части реального меню «Шёлкового Пути», расшифрованный
/// вручную по кадрам скринкаста витрины на Яндекс Еде — как временная замена
/// на время, пока нет доступа к Vendor API (см. tools/import-yandex-menu.mjs).
///
/// Расшифрован только хвост категории «Горячие блюда» — именно он был нужен
/// в моменте. Остальные категории (Холодные закуски, Салаты, Супы, Шашлык,
/// Напитки и т.д.), которые проходили через видео раньше, здесь не
/// зафиксированы: соответствующие данные не были записаны в код и не
/// пережили сжатие контекста, а пересматривать всё видео заново сочли
/// нецелесообразным — эти данные всё равно временные и будут заменены
/// настоящим импортом из API.
///
/// Подключено в [CatalogRepositoryMock] поверх двух штатных позиций —
/// намеренное расхождение с бэкенд-фолбэком (`CatalogService.
/// fallbackCatalog`), сделанное, чтобы на устройстве/симуляторе было что
/// пролистать, пока нет доступа к Vendor API.
///
/// Ограничения по сравнению с данными из API:
/// - `description` — это вес блюда с витрины (единственное, что было видно в
///   списке), а не настоящее описание блюда;
/// - фото, состав, рейтинг и вес как отдельные поля не сохранены — в модели
///   [CatalogItem] под них просто нет полей;
/// - цены и веса не перепроверялись при переносе — расхождение на десяток
///   рублей вероятно.
const List<CatalogItem> videoImportedHotDishesTail = [
  CatalogItem(
    id: 'dolma',
    categoryId: 'hot-dishes',
    name: 'Долма',
    description: '370 г',
    priceRub: 799,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'meat-bukhara',
    categoryId: 'hot-dishes',
    name: 'Мясо по-бухарски',
    description: '350 г',
    priceRub: 699,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'kurtob',
    categoryId: 'hot-dishes',
    name: 'Куртоб',
    description: '450 г',
    priceRub: 680,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'gan-fan',
    categoryId: 'hot-dishes',
    name: 'Ган-Фан',
    description: '300 г',
    priceRub: 599,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'plov-ashpaza',
    categoryId: 'hot-dishes',
    name: 'Плов от Ашпаза',
    description: '470 г',
    priceRub: 849,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'zharkoe-govyadina',
    categoryId: 'hot-dishes',
    name: 'Жаркое из говядины',
    description: '450 г',
    priceRub: 699,
    isAvailable: true,
    modifiers: [],
  ),
  CatalogItem(
    id: 'gulyash',
    categoryId: 'hot-dishes',
    name: 'Гуляш',
    description: '300 г',
    priceRub: 650,
    isAvailable: true,
    modifiers: [],
  ),
];
