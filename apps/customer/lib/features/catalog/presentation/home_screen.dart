import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/widgets/dish_image.dart';
import '../../../core/design_system/widgets/sw_bottom_sheet.dart';
import '../../../core/design_system/widgets/sw_carousel.dart';
import '../../../core/models/catalog.dart';
import '../../../core/utils/money.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../locations/presentation/providers/locations_providers.dart';
import 'item_detail_sheet.dart';
import 'providers/catalog_providers.dart';

/// Главный экран: витрина меню выбранного ресторана.
///
/// Точка входа покупательского потока (каталог -> корзина -> оформление ->
/// оплата -> статус заказа). В шапке — текущий ресторан, тап по нему открывает
/// [showLocationPicker]. Тап по блюду открывает [ItemDetailSheet].
///
/// Первый активный ресторан подставляется автоматически, чтобы пользователь
/// видел меню сразу, без обязательного выбора.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(activeLocationsProvider);
    // Default the "home restaurant" to the first active location once loaded.
    ref.listen(activeLocationsProvider, (previous, next) {
      next.whenData((locations) {
        if (locations.isNotEmpty && ref.read(selectedLocationIdProvider) == null) {
          ref.read(selectedLocationIdProvider.notifier).state = locations.first.id;
        }
      });
    });
    final selectedLocationId = ref.watch(selectedLocationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: locationsAsync.maybeWhen(
          data: (locations) {
            final selected = locations.where((l) => l.id == selectedLocationId);
            final name = selected.isNotEmpty ? selected.first.name : 'Шелковый путь';
            return InkWell(
              onTap: () => showLocationPicker(context, ref),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            );
          },
          orElse: () => const Text('Шелковый путь'),
        ),
      ),
      body: selectedLocationId == null
          ? const Center(child: CircularProgressIndicator())
          : _CatalogBody(locationId: selectedLocationId),
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody({required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider(locationId));

    return catalogAsync.when(
      data: (catalog) {
        final items = catalog.availableItems;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Вкус Центральной Азии', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 16),
            SwCarousel<CatalogItem>(
              items: items,
              itemBuilder: (context, item) => _DishCard(item: item, locationId: locationId),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Не удалось загрузить меню: $error')),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.item, required this.locationId});

  final CatalogItem item;
  final String locationId;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSwBottomSheet(
          context,
          builder: (context) => ItemDetailSheet(item: item, locationId: locationId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: DishImage(imageUrl: item.imageUrl),
              ),
              const SizedBox(height: 12),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(formatRub(item.priceRub), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
