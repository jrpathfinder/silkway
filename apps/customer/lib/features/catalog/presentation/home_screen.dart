import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/sw_bottom_sheet.dart';
import '../../../core/design_system/widgets/sw_category_chip.dart';
import '../../../core/design_system/widgets/sw_dish_card.dart';
import '../../../core/design_system/widgets/sw_empty_state.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_search_field.dart';
import '../../../core/design_system/widgets/sw_section_header.dart';
import '../../../core/design_system/widgets/sw_skeleton.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/models/catalog.dart';
import '../../cart/application/cart_notifier.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import 'item_detail_sheet.dart';
import 'providers/catalog_providers.dart';

/// Главный экран: витрина меню выбранного филиала.
///
/// Точка входа покупательского потока (каталог -> корзина -> оформление ->
/// оплата -> статус заказа).
///
/// Иерархия сверху вниз: куда доставить -> поиск -> категории -> меню
/// секциями. Порядок не случайный: сначала пользователь убеждается, что
/// адрес верный, потом ищет или листает.
///
/// Меню строится по `catalog.categories` — эти данные приходили с бэкенда и
/// раньше, но интерфейс их не использовал и показывал плоскую карусель всех
/// блюд.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Ключи для тестов. Искать по тексту хрупко: подписи меняются при правках
  /// копирайта, и тест падает там, где поведение не менялось.
  static const locationPickerKey = ValueKey('home-location-picker');
  static const searchFieldKey = ValueKey('home-search-field');

  /// Список меню. На экране два скролла (ряд категорий и само меню), и без
  /// ключа тест не может однозначно указать, какой прокручивать.
  static const menuListKey = ValueKey('home-menu-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Первый активный филиал подставляется автоматически, чтобы меню было
    // видно сразу, без обязательного выбора.
    ref.listen(activeLocationsProvider, (previous, next) {
      next.whenData((locations) {
        if (locations.isNotEmpty && ref.read(selectedLocationIdProvider) == null) {
          ref.read(selectedLocationIdProvider.notifier).state = locations.first.id;
        }
      });
    });
    final selectedLocationId = ref.watch(selectedLocationIdProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DeliveryHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, 0, SwSpacing.screenH, SwSpacing.md),
              child: SwSearchField(
                key: HomeScreen.searchFieldKey,
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
            ),
            Expanded(
              child: selectedLocationId == null
                  ? const _MenuSkeleton()
                  : _CatalogBody(locationId: selectedLocationId),
            ),
          ],
        ),
      ),
    );
  }
}

/// Шапка «куда доставляем». Раньше это был текст в AppBar, по которому было
/// неочевидно, что можно нажать, — теперь явный блок с подписью и шевроном.
class _DeliveryHeader extends ConsumerWidget {
  const _DeliveryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final locationsAsync = ref.watch(activeLocationsProvider);
    final selectedId = ref.watch(selectedLocationIdProvider);

    final name = locationsAsync.maybeWhen(
      data: (locations) {
        final selected = locations.where((l) => l.id == selectedId);
        return selected.isNotEmpty ? selected.first.name : null;
      },
      orElse: () => null,
    );

    return Semantics(
      button: true,
      label: 'Филиал доставки: ${name ?? "выбирается"}. Нажмите, чтобы сменить',
      child: InkWell(
        key: HomeScreen.locationPickerKey,
        onTap: () => showLocationPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.md, SwSpacing.screenH, SwSpacing.md),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: SwSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Доставка из', style: SwTypography.metadata.copyWith(color: scheme.onSurfaceVariant)),
                    if (name == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: SwSkeleton(width: 180, height: 17),
                      )
                    else
                      Text(
                        name,
                        style: SwTypography.h3.copyWith(color: scheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogBody extends ConsumerStatefulWidget {
  const _CatalogBody({required this.locationId});

  final String locationId;

  @override
  ConsumerState<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends ConsumerState<_CatalogBody> {
  /// null — показываем все разделы. Иначе только выбранный.
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider(widget.locationId));

    return catalogAsync.when(
      loading: () => const _MenuSkeleton(),
      error: (error, stack) => SwErrorState(
        title: 'Не удалось загрузить меню',
        details: '$error',
        // invalidate заставляет провайдер перезапросить каталог — это и есть
        // повтор, отдельной логики не требуется.
        onRetry: () => ref.invalidate(catalogProvider(widget.locationId)),
      ),
      data: (catalog) {
        final items = catalog.availableItems;
        if (items.isEmpty) {
          return const SwEmptyState(
            icon: Icons.restaurant_outlined,
            title: 'Меню пока пустое',
            message: 'В этом филиале ещё не добавили блюда. Попробуйте выбрать другой.',
          );
        }

        final categories = [...catalog.categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        // Показываем только те разделы, в которых реально есть доступные
        // блюда: пустой заголовок выглядит как ошибка загрузки.
        final visible = categories.where((c) => items.any((i) => i.categoryId == c.id)).toList();
        final shown = _categoryId == null ? visible : visible.where((c) => c.id == _categoryId).toList();

        return CustomScrollView(
          key: HomeScreen.menuListKey,
          slivers: [
            if (visible.length > 1)
              SliverToBoxAdapter(
                child: _CategoryRow(
                  categories: visible,
                  selectedId: _categoryId,
                  onSelect: (id) => setState(() => _categoryId = id),
                ),
              ),
            for (final category in shown) ...[
              SliverToBoxAdapter(child: SwSectionHeader(title: category.name)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: SwSpacing.screenH),
                sliver: SliverList.separated(
                  itemCount: items.where((i) => i.categoryId == category.id).length,
                  separatorBuilder: (_, __) => const SizedBox(height: SwSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items.where((i) => i.categoryId == category.id).elementAt(index);
                    return SwDishCard(
                      item: item,
                      heroTag: 'dish-${item.id}',
                      onTap: () => showSwBottomSheet(
                        context,
                        builder: (context) => ItemDetailSheet(item: item, locationId: widget.locationId),
                      ),
                      // Блюдо без модификаторов можно положить в корзину прямо
                      // отсюда — открывать карточку незачем. Если выбор есть,
                      // кнопку не показываем: он всё равно обязателен.
                      onAdd: item.modifiers.isEmpty
                          ? () {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .addItem(widget.locationId, item, quantity: 1);
                              showSwToast(context, '${item.name} в корзине');
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: SwSpacing.xxxl)),
          ],
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.selectedId, required this.onSelect});

  final List<CatalogCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SwSpacing.screenH),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: SwSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return SwCategoryChip(
              label: 'Всё',
              selected: selectedId == null,
              onTap: () => onSelect(null),
            );
          }
          final category = categories[index - 1];
          return SwCategoryChip(
            label: category.name,
            selected: selectedId == category.id,
            // Повторный тап по выбранной категории снимает фильтр — иначе
            // пришлось бы целиться в «Всё».
            onTap: () => onSelect(selectedId == category.id ? null : category.id),
          );
        },
      ),
    );
  }
}

/// Скелетон меню. Повторяет структуру готового экрана — чипы категорий и
/// карточки, — поэтому появление данных не выглядит скачком.
class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: SwSpacing.screenH),
      children: [
        Row(
          children: [
            for (final w in [64.0, 96.0, 80.0]) ...[
              SwSkeleton(width: w, height: 36, radius: SwSpacing.radiusXl),
              const SizedBox(width: SwSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: SwSpacing.xxl),
        const SwSkeleton(width: 160, height: 22),
        const SizedBox(height: SwSpacing.md),
        for (var i = 0; i < 3; i++) ...[
          const _DishCardSkeleton(),
          const SizedBox(height: SwSpacing.md),
        ],
      ],
    );
  }
}

class _DishCardSkeleton extends StatelessWidget {
  const _DishCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 16 / 10, child: SwSkeleton(radius: 0, height: double.infinity)),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(SwSpacing.md),
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwSkeleton(width: 140, height: 16),
                SizedBox(height: SwSpacing.sm),
                SwSkeleton(width: double.infinity, height: 12),
                SizedBox(height: SwSpacing.sm),
                SwSkeleton(width: 70, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
