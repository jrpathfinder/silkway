import 'package:flutter/material.dart';

import '../../models/catalog.dart';
import '../../utils/money.dart';
import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';
import 'dish_image.dart';

/// Карточка блюда в меню.
///
/// Порядок считывания: фото → название → описание → цена. Фотография —
/// самый сильный элемент, поэтому занимает верх карточки целиком и всегда в
/// одной пропорции: разные соотношения в списке выглядят неопрятно.
///
/// Кнопка «+» добавляет блюдо без открытия карточки — для блюд без
/// модификаторов это экономит два тапа. Если у блюда есть модификаторы,
/// [onAdd] не передаётся: выбор всё равно нужен, и тап открывает шторку.
class SwDishCard extends StatelessWidget {
  const SwDishCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAdd,
    this.heroTag,
  });

  final CatalogItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final image = AspectRatio(
      aspectRatio: 16 / 10,
      child: DishImage(imageUrl: item.imageUrl, borderRadius: BorderRadius.zero),
    );

    return Semantics(
      button: true,
      // Цена отдельной строкой в подписи: VoiceOver иначе зачитает её слитно
      // с описанием и на слух это неразборчиво.
      label: '${item.name}. ${formatRub(item.priceRub)}',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  heroTag == null ? image : Hero(tag: heroTag!, child: image),
                  if (onAdd != null)
                    Positioned(
                      right: SwSpacing.sm,
                      bottom: SwSpacing.sm,
                      child: _AddButton(onPressed: onAdd!, label: item.name),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(SwSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: SwTypography.h3.copyWith(color: scheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: SwSpacing.xs),
                    Text(
                      item.description,
                      style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SwSpacing.sm),
                    Text(formatRub(item.priceRub), style: SwTypography.price.copyWith(color: scheme.onSurface)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Добавить в корзину: $label',
      child: Material(
        color: scheme.surface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          // 44 — минимальная цель нажатия по рекомендациям Apple; визуально
          // кружок меньше, но область касания должна остаться полной.
          child: SizedBox(
            width: SwSpacing.minTapTarget,
            height: SwSpacing.minTapTarget,
            child: Icon(Icons.add_rounded, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
