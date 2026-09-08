import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/tokens/sw_spacing.dart';
import '../../../core/design_system/tokens/sw_typography.dart';
import '../../../core/design_system/widgets/dish_image.dart';
import '../../../core/design_system/widgets/sw_quantity_stepper.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/models/catalog.dart';
import '../../../core/utils/money.dart';
import '../../cart/application/cart_notifier.dart';

/// Карточка блюда — нижняя шторка.
///
/// Порядок: фото -> название и цена -> описание -> выбор -> количество ->
/// кнопка. Кнопка всегда на виду, потому что это единственное действие
/// экрана; всё остальное над ней прокручивается.
///
/// Логика выбора модификаторов и расчёт цены за единицу намеренно оставлены
/// без изменений — редизайн трогает только подачу. Итог всё равно
/// пересчитывает сервер при создании заказа.
class ItemDetailSheet extends ConsumerStatefulWidget {
  const ItemDetailSheet({super.key, required this.item, required this.locationId});

  final CatalogItem item;
  final String locationId;

  @override
  ConsumerState<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<ItemDetailSheet> {
  int _quantity = 1;
  final Set<String> _selectedModifierIds = {};

  double get _unitPrice =>
      widget.item.priceRub +
      widget.item.modifiers.where((m) => _selectedModifierIds.contains(m.id)).fold(0.0, (sum, m) => sum + m.priceRub);

  void _add() {
    // Добавление в корзину — результат осознанного действия, здесь уместен
    // отклик заметнее, чем при перещёлкивании количества.
    HapticFeedback.mediumImpact();
    final item = widget.item;
    final modifiers = item.modifiers.where((m) => _selectedModifierIds.contains(m.id)).toList();
    ref.read(cartNotifierProvider.notifier).addItem(
          widget.locationId,
          item,
          quantity: _quantity,
          modifiers: modifiers,
        );
    Navigator.of(context).pop();
    showSwToast(context, '${item.name} в корзине');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;

    // ConstrainedBox здесь обязателен, и вот почему.
    //
    // showSwBottomSheet вызывает showModalBottomSheet(isScrollControlled:
    // true) — тот спрашивает у содержимого «какой ты высоты?», передавая
    // НЕОГРАНИЧЕННУЮ высоту, чтобы подогнать шторку под контент. В таких
    // условиях SingleChildScrollView никогда не включает прокрутку: он просто
    // сообщает свою полную натуральную высоту, а лишнее молча обрезается
    // ограничением высоты самой шторки.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imageUrl != null)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Тот же тег, что у карточки в меню, — фото перелетает в
                        // шторку, а не появляется заново.
                        Hero(
                          tag: 'dish-${item.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(SwSpacing.radiusLg),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: DishImage(imageUrl: item.imageUrl, borderRadius: BorderRadius.zero),
                            ),
                          ),
                        ),
                        if (item.originalPriceRub != null)
                          Positioned(
                            left: SwSpacing.md,
                            bottom: -SwSpacing.md,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.percent_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(SwSpacing.xl, SwSpacing.xl, SwSpacing.xl, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Вес — не часть названия, а его происхождение другое (с витрины,
                        // не из description) заслуживает отдельного поля, а не конкатенации.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(child: Text(item.name, style: SwTypography.h1.copyWith(color: scheme.onSurface))),
                            if (item.weightLabel != null) ...[
                              const SizedBox(width: SwSpacing.sm),
                              Text(
                                item.weightLabel!,
                                style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: SwSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              formatRub(item.priceRub),
                              style: SwTypography.priceLarge.copyWith(color: scheme.primary),
                            ),
                            if (item.originalPriceRub != null) ...[
                              const SizedBox(width: SwSpacing.sm),
                              Text(
                                formatRub(item.originalPriceRub!),
                                style: SwTypography.body.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.ratingPercent != null) ...[
                          const SizedBox(height: SwSpacing.sm),
                          Row(
                            children: [
                              Icon(Icons.thumb_up_alt_outlined, size: 16, color: scheme.onSurfaceVariant),
                              const SizedBox(width: SwSpacing.xs),
                              Text('${item.ratingPercent}%', style: SwTypography.bodyStrong.copyWith(color: scheme.onSurface)),
                              const SizedBox(width: SwSpacing.xs),
                              Text('(${item.ratingCount})', style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                        const SizedBox(height: SwSpacing.md),
                        Text(
                          item.description,
                          style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (item.composition != null) ...[
                          const SizedBox(height: SwSpacing.xxl),
                          Text('Состав', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
                          const SizedBox(height: SwSpacing.sm),
                          Text(item.composition!, style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                        if (item.nutritionPer100g != null) ...[
                          const SizedBox(height: SwSpacing.xxl),
                          Text('На 100 г', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
                          const SizedBox(height: SwSpacing.sm),
                          _NutritionFactsRow(facts: item.nutritionPer100g!),
                        ],
                        if (item.modifiers.isNotEmpty) ...[
                          const SizedBox(height: SwSpacing.xxl),
                          Text(
                            item.modifierGroupLabel ?? 'Добавить к блюду',
                            style: SwTypography.h3.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: SwSpacing.sm),
                          for (final modifier in item.modifiers)
                            _ModifierRow(
                              modifier: modifier,
                              selected: _selectedModifierIds.contains(modifier.id),
                              onChanged: (checked) => setState(() {
                                if (checked) {
                                  _selectedModifierIds.add(modifier.id);
                                } else {
                                  _selectedModifierIds.remove(modifier.id);
                                }
                              }),
                            ),
                        ],
                        const SizedBox(height: SwSpacing.xxl),
                        Center(
                          child: SwQuantityStepper(
                            quantity: _quantity,
                            onIncrement: () => setState(() => _quantity++),
                            onDecrement: () => setState(() => _quantity--),
                          ),
                        ),
                        const SizedBox(height: SwSpacing.xl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SwStickyCtaBar(
            label: 'Добавить в корзину',
            priceLabel: formatRub(_unitPrice * _quantity),
            onTap: _add,
          ),
        ],
      ),
    );
  }
}

/// БЖУ на 100 г — четыре колонки в одной плашке, а не список строк: значений
/// всего четыре и они короткие, табличный вид читается быстрее.
class _NutritionFactsRow extends StatelessWidget {
  const _NutritionFactsRow({required this.facts});

  final CatalogNutritionFacts facts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      (_formatNumber(facts.caloriesKcal), 'ккал'),
      (_formatNumber(facts.proteinG), 'белки'),
      (_formatNumber(facts.fatG), 'жиры'),
      (_formatNumber(facts.carbsG), 'углеводы'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: SwSpacing.md, horizontal: SwSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (value, label) in entries)
            Column(
              children: [
                Text(value, style: SwTypography.bodyStrong.copyWith(color: scheme.onSurface)),
                const SizedBox(height: SwSpacing.xs),
                Text(label, style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
        ],
      ),
    );
  }

  String _formatNumber(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}

/// Строка модификатора.
///
/// Вместо `CheckboxListTile` — своя строка: у стандартной чекбокс слева, а
/// доплата уезжает в `secondary` справа от названия, из-за чего цена и
/// переключатель смешиваются. Здесь порядок постоянный: название, доплата,
/// переключатель.
class _ModifierRow extends StatelessWidget {
  const _ModifierRow({required this.modifier, required this.selected, required this.onChanged});

  final CatalogModifier modifier;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      // Доплату проговариваем в подписи: иначе VoiceOver зачитает только
      // название и переключатель, а цена останется незамеченной.
      label: '${modifier.name}, плюс ${formatRub(modifier.priceRub)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
        onTap: () => onChanged(!selected),
        child: Container(
          constraints: const BoxConstraints(minHeight: SwSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: SwSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(modifier.name, style: SwTypography.body.copyWith(color: scheme.onSurface)),
              ),
              Text(
                '+${formatRub(modifier.priceRub)}',
                style: SwTypography.price.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: SwSpacing.sm),
              ExcludeSemantics(
                child: Checkbox(
                  value: selected,
                  onChanged: (v) => onChanged(v ?? false),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SwSpacing.xs + 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
