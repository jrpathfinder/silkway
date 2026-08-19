import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/catalog.dart';
import '../domain/cart.dart';

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  void addItem(String locationId, CatalogItem item, {required int quantity, List<CatalogModifier> modifiers = const []}) {
    final candidate = CartLine(item: item, quantity: quantity, selectedModifiers: modifiers);
    final existingIndex = state.lines.indexWhere((line) => line.sameSelectionAs(candidate));

    final updatedLines = [...state.lines];
    if (existingIndex >= 0) {
      updatedLines[existingIndex] = updatedLines[existingIndex].copyWith(
        quantity: updatedLines[existingIndex].quantity + quantity,
      );
    } else {
      updatedLines.add(candidate);
    }
    state = state.copyWith(locationId: locationId, lines: updatedLines);
  }

  void updateQuantity(int lineIndex, int quantity) {
    if (quantity <= 0) {
      removeLine(lineIndex);
      return;
    }
    final updatedLines = [...state.lines];
    updatedLines[lineIndex] = updatedLines[lineIndex].copyWith(quantity: quantity);
    state = state.copyWith(lines: updatedLines);
  }

  void removeLine(int lineIndex) {
    final updatedLines = [...state.lines]..removeAt(lineIndex);
    state = state.copyWith(lines: updatedLines);
  }

  void clear() => state = const Cart();
}

final cartNotifierProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
