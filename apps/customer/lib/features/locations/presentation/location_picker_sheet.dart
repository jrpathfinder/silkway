import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/widgets/sw_bottom_sheet.dart';
import '../../../core/design_system/widgets/sw_error_state.dart';
import '../../../core/design_system/widgets/sw_skeleton.dart';
import '../../../core/models/location.dart';
import 'providers/locations_providers.dart';

/// The "Выберите ресторан" bottom sheet from the design reference — replaces
/// full-page navigation with a sheet triggered from the home header dropdown.
Future<void> showLocationPicker(BuildContext context, WidgetRef ref) {
  return showSwBottomSheet(
    context,
    builder: (context) => const _LocationPickerContent(),
  );
}

class _LocationPickerContent extends ConsumerWidget {
  const _LocationPickerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(activeLocationsProvider);
    final selectedId = ref.watch(selectedLocationIdProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ВЫБЕРИТЕ РЕСТОРАН', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          locationsAsync.when(
            data: (locations) => Column(
              children: [for (final location in locations) _LocationTile(location: location, selected: location.id == selectedId)],
            ),
            loading: () => const Column(
              children: [
                SwSkeleton(width: double.infinity, height: 76, radius: SwSpacing.radiusLg),
                SizedBox(height: SwSpacing.md),
                SwSkeleton(width: double.infinity, height: 76, radius: SwSpacing.radiusLg),
              ],
            ),
            error: (error, stack) => SwErrorState(
              title: 'Не удалось загрузить филиалы',
              details: '$error',
              onRetry: () => ref.invalidate(activeLocationsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends ConsumerWidget {
  const _LocationTile({required this.location, required this.selected});

  final RestaurantLocation location;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ref.read(selectedLocationIdProvider.notifier).state = location.id;
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, color: selected ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.name, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? scheme.primary : null)),
                      Text(location.address, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
