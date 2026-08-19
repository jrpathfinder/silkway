import '../../../core/models/catalog.dart';

/// Client-side cart line. This is a client *estimate* only — the backend
/// always re-fetches the catalog and recomputes prices server-side at order
/// creation (OrdersService.create), so nothing here is trusted as final.
class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    required this.selectedModifiers,
  });

  final CatalogItem item;
  final int quantity;
  final List<CatalogModifier> selectedModifiers;

  double get unitPriceRub => item.priceRub + selectedModifiers.fold(0.0, (sum, m) => sum + m.priceRub);

  double get totalRub => unitPriceRub * quantity;

  /// Two lines are "the same line" for merge/update purposes when they're the
  /// same item with the same modifier selection (matching quantity separately).
  bool sameSelectionAs(CartLine other) {
    if (item.id != other.item.id) return false;
    final a = selectedModifiers.map((m) => m.id).toList()..sort();
    final b = other.selectedModifiers.map((m) => m.id).toList()..sort();
    return a.join(',') == b.join(',');
  }

  CartLine copyWith({int? quantity}) => CartLine(
        item: item,
        quantity: quantity ?? this.quantity,
        selectedModifiers: selectedModifiers,
      );

  /// Deterministic string identifying this line's item+modifier selection —
  /// used both as a merge key and as part of the checkout idempotency-key
  /// fingerprint (see IdempotencyKeyStore).
  String get signature {
    final modifierIds = selectedModifiers.map((m) => m.id).toList()..sort();
    return '${item.id}:$quantity:${modifierIds.join(',')}';
  }
}

class Cart {
  const Cart({this.locationId, this.lines = const []});

  final String? locationId;
  final List<CartLine> lines;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get totalRub => lines.fold(0.0, (sum, line) => sum + line.totalRub);

  bool get isEmpty => lines.isEmpty;

  /// Stable fingerprint of the whole cart, used to key the idempotency store —
  /// sorted so line order never affects it.
  String get fingerprint {
    final signatures = lines.map((l) => l.signature).toList()..sort();
    return signatures.join('|');
  }

  Cart copyWith({String? locationId, List<CartLine>? lines}) => Cart(
        locationId: locationId ?? this.locationId,
        lines: lines ?? this.lines,
      );
}
