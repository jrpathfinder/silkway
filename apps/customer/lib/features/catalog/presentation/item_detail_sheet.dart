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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(SwSpacing.xl, SwSpacing.xl, SwSpacing.xl, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: SwTypography.h1.copyWith(color: scheme.onSurface)),
                        const SizedBox(height: SwSpacing.xs),
                        Text(
                          formatRub(item.priceRub),
                          style: SwTypography.priceLarge.copyWith(color: scheme.primary),
                        ),
                        const SizedBox(height: SwSpacing.md),
                        Text(
                          item.description,
                          style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (item.modifiers.isNotEmpty) ...[
                          const SizedBox(height: SwSpacing.xxl),
                          Text('Добавить к блюду', style: SwTypography.h3.copyWith(color: scheme.onSurface)),
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
