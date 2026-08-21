import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Чип категории меню.
///
/// Категории приходят с бэкенда (`CatalogResponse.categories`), но до
/// редизайна интерфейс их не использовал вовсе — меню было плоским списком.
///
/// Выбранное состояние передаётся не только цветом, но и насыщенностью фона
/// с толщиной шрифта: полагаться на один лишь цвет нельзя.
class SwCategoryChip extends StatelessWidget {
  const SwCategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SwSpacing.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(SwSpacing.radiusXl),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: SwSpacing.minTapTarget - 8),
            padding: const EdgeInsets.symmetric(horizontal: SwSpacing.lg, vertical: SwSpacing.sm),
            alignment: Alignment.center,
            child: Text(
              label,
              style: SwTypography.bodyStrong.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
