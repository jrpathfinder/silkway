import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/widgets/dish_image.dart';
import '../../../core/design_system/widgets/sw_quantity_stepper.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/models/catalog.dart';
import '../../../core/utils/money.dart';
import '../../cart/application/cart_notifier.dart';

/// Нижняя шторка с карточкой блюда (по референсу «Империя Пиццы»):
/// белая карточка с фото и крупной ценой, чекбоксы модификаторов,
/// счётчик количества и кнопка «Добавить в корзину {цена}» внизу.
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // ConstrainedBox здесь обязателен, и вот почему.
    //
    // showSwBottomSheet вызывает showModalBottomSheet(isScrollControlled:
    // true) — тот спрашивает у содержимого «какой ты высоты?», передавая
    // НЕОГРАНИЧЕННУЮ высоту, чтобы подогнать шторку под контент. В таких
    // условиях SingleChildScrollView никогда не включает прокрутку: он просто
    // сообщает свою полную натуральную высоту, а лишнее потом молча
    // обрезается ограничением высоты самой шторки.
    //
    // Ограничивая высоту здесь, мы даём прокрутке реальную границу — и
    // высокое фото, длинное описание или несколько модификаторов
    // прокручиваются, а не срезаются.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.imageUrl != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatRub(item.priceRub),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: DishImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
              if (item.modifiers.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...item.modifiers.map(
                  (modifier) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedModifierIds.contains(modifier.id),
                    title: Text(modifier.name),
                    secondary: Text('+${formatRub(modifier.priceRub)}'),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selectedModifierIds.add(modifier.id);
                      } else {
                        _selectedModifierIds.remove(modifier.id);
                      }
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: SwQuantityStepper(
                  quantity: _quantity,
                  onIncrement: () => setState(() => _quantity++),
                  onDecrement: () => setState(() => _quantity--),
                ),
              ),
              const SizedBox(height: 20),
              SwStickyCtaBar(
                label: 'Добавить в корзину',
                priceLabel: formatRub(_unitPrice * _quantity),
                onTap: () {
                  final modifiers = item.modifiers.where((m) => _selectedModifierIds.contains(m.id)).toList();
                  ref.read(cartNotifierProvider.notifier).addItem(
                        widget.locationId,
                        item,
                        quantity: _quantity,
                        modifiers: modifiers,
                      );
                  Navigator.of(context).pop();
                  showSwToast(context, '${item.name} добавлено в корзину');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
