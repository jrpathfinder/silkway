import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Ошибка с возможностью повторить.
///
/// Раньше на экранах стояло `Text('Ошибка: $error')` — пользователю это
/// ничего не говорит и ничего не предлагает. Здесь: что не получилось, что
/// сделать, и кнопка повтора.
///
/// Техническая подробность ([details]) прячется под спойлер: она нужна при
/// разборе, но не должна быть первым, что видит человек.
class SwErrorState extends StatelessWidget {
  const SwErrorState({
    super.key,
    required this.title,
    required this.onRetry,
    this.message = 'Проверьте соединение и попробуйте ещё раз.',
    this.details,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SwSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: SwSpacing.lg),
            Text(title, style: SwTypography.h2.copyWith(color: scheme.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: SwSpacing.sm),
            Text(
              message,
              style: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SwSpacing.xxl),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(200, SwSpacing.minTapTarget + 4)),
              child: const Text('Повторить'),
            ),
            if (details != null) ...[
              const SizedBox(height: SwSpacing.md),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text('Подробности', style: SwTypography.metadata.copyWith(color: scheme.onSurfaceVariant)),
                children: [
                  Text(details!, style: SwTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
