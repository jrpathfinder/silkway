import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Управление количеством: −/число/+.
///
/// Один компонент на карточку блюда и корзину, чтобы логика количества не
/// разошлась между экранами.
///
/// Кнопки намеренно разного веса: «+» — основное действие и красится в
/// акцент, «−» нейтральная. Стандартный `IconButton.filledTonal` тут не
/// подходит: он берёт `secondaryContainer`, а вторичный цвет темы — индиго,
/// и рядом с терракотовым плюсом синий минус читается как чужой элемент.
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
    final scheme = Theme.of(context).colorScheme;
    final canDecrement = quantity > minQuantity;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Button(
          icon: Icons.remove_rounded,
          onPressed: canDecrement ? onDecrement : null,
          background: scheme.surfaceContainerHighest,
          foreground: canDecrement ? scheme.onSurface : scheme.outlineVariant,
          tooltip: 'Меньше',
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: SwTypography.price.copyWith(color: scheme.onSurface),
          ),
        ),
        _Button(
          icon: Icons.add_rounded,
          onPressed: onIncrement,
          background: scheme.primary,
          foreground: scheme.onPrimary,
          tooltip: 'Больше',
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: SwSpacing.minTapTarget,
            height: SwSpacing.minTapTarget,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
