import 'package:flutter/material.dart';

import '../../models/catalog.dart';
import '../../utils/money.dart';
import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';
import 'dish_image.dart';

/// Строка блюда в меню.
///
/// Раскладка горизонтальная: текст слева, фото справа. Раньше карточка была
/// вертикальной, с фотографией во всю ширину — выглядело эффектно, но на
/// экран помещалось меньше двух позиций, и меню приходилось прокручивать,
/// чтобы понять, что вообще есть. В горизонтальной строке помещается пять-
/// шесть, а меню читается списком, а не листается по одной картинке.
///
/// Фото при этом остаётся: квадрат фиксированного размера, одинаковый у всех
/// строк — разные пропорции в списке выглядят неопрятно.
///
/// Кнопка «+» добавляет блюдо без открытия карточки — для блюд без
/// модификаторов это экономит два тапа. Если модификаторы есть, [onAdd] не
/// передаётся: выбор всё равно нужен, и тап открывает шторку.
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

  /// Сторона фотографии. Достаточно, чтобы блюдо было узнаваемо, и при этом
  /// строка остаётся низкой.
  static const _imageSide = 96.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
      child: SizedBox(
        width: _imageSide,
        height: _imageSide,
        child: DishImage(imageUrl: item.imageUrl, borderRadius: BorderRadius.zero),
      ),
    );

    return Semantics(
      button: true,
      // Цена отдельным предложением: VoiceOver иначе зачитает её слитно с
      // описанием и на слух это неразборчиво.
      label: '${item.name}. ${formatRub(item.priceRub)}',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SwSpacing.md),
            child: Row(
              // По центру, а не по верху: высоту строки задаёт фотография, и
              // у блюд с коротким описанием под ценой оставалась заметная
              // пустота. При длинном описании текст выше фото — тогда по
              // центру встаёт уже оно.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: SwTypography.h3.copyWith(color: scheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                const SizedBox(width: SwSpacing.md),
                // Кнопка выходит за угол фотографии: внутри 96 px она
                // накрыла бы четверть блюда, а уменьшать её нельзя —
                // 44 pt это минимальная цель нажатия по рекомендациям Apple.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    heroTag == null ? image : Hero(tag: heroTag!, child: image),
                    if (onAdd != null)
                      Positioned(
                        right: -SwSpacing.xs,
                        bottom: -SwSpacing.xs,
                        child: _AddButton(onPressed: onAdd!, label: item.name),
                      ),
                  ],
                ),
              ],
            ),
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
