import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Заголовок раздела меню. Помечен как заголовок для VoiceOver — так по
/// разделам можно перемещаться жестом, не вычитывая весь список.
class SwSectionHeader extends StatelessWidget {
  const SwSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SwSpacing.screenH, SwSpacing.xxl, SwSpacing.screenH, SwSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: SwTypography.h2.copyWith(color: scheme.onSurface)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
