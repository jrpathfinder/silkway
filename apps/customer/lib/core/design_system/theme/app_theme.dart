import 'package:flutter/material.dart';

// TODO(design): replace seed color/typography with final brand guidelines
// once provided — this reuses the placeholder seed from the original shell,
// it is not a final visual-identity decision.
/// Тема приложения. Цвета временные — ждут финального брендбука.
class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffb9633d)),
        scaffoldBackgroundColor: const Color(0xfffaf8f4),
      );
}
