import 'package:flutter/material.dart';

/// Цвета бренда и обе палитры приложения.
///
/// Подход: современный интерфейс первым планом, Средняя Азия — акцентами.
/// Терракота и индиго взяты из керамики и текстиля, но работают как обычные
/// UI-цвета, а не как орнамент.
///
/// Экраны берут цвета из `Theme.of(context).colorScheme`, а не отсюда
/// напрямую — иначе тёмная тема разъедется. Прямые ссылки на [SwColors]
/// допустимы только внутри `app_theme.dart`.
abstract final class SwColors {
  // ── Бренд ────────────────────────────────────────────────────────────────
  // Три цвета взяты напрямую с логотипа («Чайхана Шёлковый путь» на шёлковой
  // ткани) — по одному из красного, синего и жёлтого/золотого спектра ткани
  // и вышивки, а не абстрактно подобранные «восточные» тона.

  /// Красный — основное действие. Взят из красных секций ткани на логотипе.
  static const terracotta = Color(0xff9C3A2C);
  static const terracottaLight = Color(0xffE3AC9B);

  /// Синий — вторичный акцент. Взят из индиго-секций ткани на логотипе.
  static const indigo = Color(0xff1F3D63);
  static const indigoLight = Color(0xff8CA3CC);

  /// Золото — подсветка избранного и акций. Взято из вышивки логотипа.
  static const brass = Color(0xffC89A3D);

  /// Тёмно-коричневый фон заставки. Держим здесь, чтобы значение не
  /// расходилось с pubspec.yaml и SplashScreen.
  static const espresso = Color(0xff2A211A);

  // ── Светлая тема ─────────────────────────────────────────────────────────
  /// Песочный, а не белый: на белом фоне фотографии блюд выглядят вырезанными.
  static const sand = Color(0xffFAF7F2);
  static const surfaceLight = Color(0xffFFFFFF);
  static const surfaceAltLight = Color(0xffF2EEE7);
  static const inkLight = Color(0xff1C1714);
  static const inkSoftLight = Color(0xff6B615A);
  static const hairlineLight = Color(0xffE6E0D7);

  // ── Тёмная тема ──────────────────────────────────────────────────────────
  /// Не чёрный, а тёплый тёмный — родственник espresso, чтобы фотографии
  /// блюд не выглядели холодными.
  static const groundDark = Color(0xff17130F);
  static const surfaceDark = Color(0xff211C17);
  static const surfaceAltDark = Color(0xff2B241E);
  static const inkDark = Color(0xffF2EDE7);
  static const inkSoftDark = Color(0xffB0A69C);
  static const hairlineDark = Color(0xff372F28);

  /// В тёмной теме терракота выцветает и теряет контраст — берём осветлённую.
  static const terracottaDark = Color(0xffDD8058);
  static const indigoOnDark = Color(0xff9FB6DE);

  // ── Статусы ──────────────────────────────────────────────────────────────
  // Отдельные от акцента: статус заказа не должен зависеть от брендового
  // цвета. Плюс статус нигде не передаётся одним лишь цветом — рядом всегда
  // текст или иконка (требование доступности).
  static const success = Color(0xff2E7D5B);
  static const successDark = Color(0xff6DBF9A);
  static const warning = Color(0xffB87503);
  static const warningDark = Color(0xffE0A73C);
  static const error = Color(0xffB3261E);
  static const errorDark = Color(0xffE59189);
}
