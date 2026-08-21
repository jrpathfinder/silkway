import 'package:flutter/material.dart';

import '../tokens/sw_colors.dart';
import '../tokens/sw_spacing.dart';
import '../tokens/sw_typography.dart';

/// Темы приложения — светлая и тёмная.
///
/// Собираются из токенов (`design_system/tokens/`), а не из литералов по
/// месту. Экраны должны брать цвета через `Theme.of(context).colorScheme`:
/// прямые ссылки на [SwColors] за пределами этого файла ломают тёмную тему.
///
/// Раньше тема строилась через `ColorScheme.fromSeed` от одного цвета —
/// Material генерировал остальные сам, и попадания в брендовую палитру не
/// было. Теперь ключевые роли заданы явно.
abstract final class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: SwColors.terracotta,
          onPrimary: Colors.white,
          primaryContainer: SwColors.terracottaLight,
          onPrimaryContainer: SwColors.espresso,
          secondary: SwColors.indigo,
          onSecondary: Colors.white,
          surface: SwColors.surfaceLight,
          onSurface: SwColors.inkLight,
          surfaceContainerHighest: SwColors.surfaceAltLight,
          onSurfaceVariant: SwColors.inkSoftLight,
          outlineVariant: SwColors.hairlineLight,
          error: SwColors.error,
          onError: Colors.white,
        ),
        ground: SwColors.sand,
        ink: SwColors.inkLight,
        inkSoft: SwColors.inkSoftLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: SwColors.terracottaDark,
          onPrimary: SwColors.espresso,
          primaryContainer: Color(0xff5C2C18),
          onPrimaryContainer: Color(0xffFFD9C8),
          secondary: SwColors.indigoOnDark,
          onSecondary: SwColors.espresso,
          surface: SwColors.surfaceDark,
          onSurface: SwColors.inkDark,
          surfaceContainerHighest: SwColors.surfaceAltDark,
          onSurfaceVariant: SwColors.inkSoftDark,
          outlineVariant: SwColors.hairlineDark,
          error: SwColors.errorDark,
          onError: SwColors.espresso,
        ),
        ground: SwColors.groundDark,
        ink: SwColors.inkDark,
        inkSoft: SwColors.inkSoftDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color ground,
    required Color ink,
    required Color inkSoft,
  }) {
    final text = SwTypography.themeFor(ink, inkSoft);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      textTheme: text,
      // Фон приложения песочный, а карточки белые — если не задать цвет явно,
      // Material подмешивает тон поверхности и разница пропадает.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SwSpacing.radiusLg)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SwTypography.h2.copyWith(color: ink),
        iconTheme: IconThemeData(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: SwTypography.bodyStrong,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SwSpacing.radiusMd)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(SwTypography.metadata.copyWith(color: inkSoft)),
        height: 64,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(SwSpacing.radiusXl)),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SwSpacing.radiusMd)),
      ),
    );
  }
}
