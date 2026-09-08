import 'package:flutter/material.dart';

import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Поле поиска.
///
/// Используется в двух режимах. На главном экране — как кнопка ([readOnly] =
/// true): тап открывает экран поиска, ввод там. Внутри экрана поиска — как
/// настоящее поле с автофокусом.
///
/// Разделение нужно, чтобы на главном не появлялась клавиатура при случайном
/// касании и чтобы поиск открывался полноэкранно, а не ютился в шапке.
class SwSearchField extends StatelessWidget {
  const SwSearchField({
    super.key,
    this.controller,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText = 'Поиск блюд и категорий',
  });

  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool readOnly;
  final bool autofocus;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = controller?.text.isNotEmpty ?? false;

    return Semantics(
      textField: !readOnly,
      button: readOnly,
      label: readOnly ? 'Поиск блюд и категорий' : null,
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        readOnly: readOnly,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: SwTypography.body.copyWith(color: scheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: SwTypography.body.copyWith(color: scheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
          suffixIcon: hasText && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: scheme.onSurfaceVariant,
                  onPressed: onClear,
                  tooltip: 'Очистить',
                )
              : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: SwSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SwSpacing.radiusMd),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
