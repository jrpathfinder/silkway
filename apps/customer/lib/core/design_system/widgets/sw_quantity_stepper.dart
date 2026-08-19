import 'package:flutter/material.dart';

/// -/count/+ control shared by the item-detail sheet and cart line items —
/// one implementation so quantity logic can't drift between the two.
class SwQuantityStepper extends StatelessWidget {
  const SwQuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.minQuantity = 1,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minQuantity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: quantity > minQuantity ? onDecrement : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 32,
          child: Text('$quantity', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton.filled(onPressed: onIncrement, icon: const Icon(Icons.add)),
      ],
    );
  }
}
