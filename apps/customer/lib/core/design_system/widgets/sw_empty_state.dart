import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Пустое состояние: иконка, заголовок, пояснение и действие.
///
/// Пустой экран — это ещё не тупик, а развилка: у пользователя всегда должен
/// быть очевидный следующий шаг. Поэтому [actionLabel] и [onAction] стоит
/// заполнять везде, где действие вообще осмысленно.
class SwEmptyState extends StatelessWidget {
  const SwEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: SwSpacing.xl),
            Text(title, style: SwTypography.h2.copyWith(color: scheme.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: SwSpacing.sm),
            Text(
              message,
              style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SwSpacing.xxl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(200, SwSpacing.minTapTarget + 4)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
