import 'package:flutter/material.dart';

/// Bottom-pinned "label + price" CTA bar — used for both "Add to cart
/// {price}" (item detail) and "Checkout {total}" (cart).
class SwStickyCtaBar extends StatelessWidget {
  const SwStickyCtaBar({
    super.key,
    required this.label,
    required this.priceLabel,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String priceLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
