import 'package:flutter/material.dart';

/// Типографическая шкала.
///
/// Системный шрифт выбран намеренно: на iOS это SF Pro, и интерфейс сразу
/// читается как родной, а не как веб внутри айфона. Плюс он умеет Dynamic
/// Type без дополнительной работы.
///
/// Размеры задаются в логических пикселях, но нигде не фиксируется высота
/// контейнеров под текст — иначе при крупном системном шрифте строки
/// обрежутся.
abstract final class SwTypography {
  /// Заголовок-витрина: приветствие на главном, крупные промо.
  static const display = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15);

  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.2);
  static const h2 = TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25);
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45);
  static const bodyStrong = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.45);

  /// Описание блюда, подписи под полями.
  static const caption = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.35);

  /// Служебное: разделы, состояния, «Товаров: 3». С разрядкой — так короткие
  /// строчные подписи читаются лучше.
  static const metadata = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3, height: 1.3);

  /// Цена. Моноширинные цифры обязательны: без них суммы в списке пляшут по
  /// ширине и колонка выглядит кривой.
  static const price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.2,
  );
  static const priceLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.15,
  );

  /// Собирает Material TextTheme из шкалы выше, чтобы стандартные виджеты
  /// (AppBar, ListTile, кнопки) подчинялись тем же правилам.
  static TextTheme themeFor(Color ink, Color inkSoft) => TextTheme(
        displaySmall: display.copyWith(color: ink),
        headlineMedium: h1.copyWith(color: ink),
        headlineSmall: h2.copyWith(color: ink),
        titleMedium: h3.copyWith(color: ink),
        bodyMedium: body.copyWith(color: ink),
        bodySmall: caption.copyWith(color: inkSoft),
        labelMedium: metadata.copyWith(color: inkSoft),
      );
}
