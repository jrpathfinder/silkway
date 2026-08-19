import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/widgets/sw_quantity_stepper.dart';
import '../../../core/design_system/widgets/sw_sticky_cta_bar.dart';
import '../../../core/design_system/widgets/sw_toast.dart';
import '../../../core/models/catalog.dart';
import '../../../core/utils/money.dart';
import '../../cart/application/cart_notifier.dart';

/// The item-detail bottom sheet from the design reference: modifier
/// checkboxes, quantity stepper, sticky "Add to cart {price}" CTA.
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
      widget.item.modifiers
          .where((m) => _selectedModifierIds.contains(m.id))
          .fold(0.0, (sum, m) => sum + m.priceRub);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}
