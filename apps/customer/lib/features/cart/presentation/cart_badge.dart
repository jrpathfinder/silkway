import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/cart_notifier.dart';

class CartBadge extends ConsumerWidget {
  const CartBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartNotifierProvider.select((cart) => cart.itemCount));
    if (itemCount == 0) return child;
    return Badge(label: Text('$itemCount'), child: child);
  }
}
