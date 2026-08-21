/// Шкала отступов. Всё кратно 4 — так вертикальный ритм не расползается,
/// когда экраны собирают разные люди.
///
/// Пользоваться этими константами, а не числами по месту: именно из-за
/// произвольных `EdgeInsets.all(13)` интерфейс начинает выглядеть собранным
/// наспех.
abstract final class SwSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Горизонтальные поля экрана. Один и тот же отступ у всех экранов —
  /// иначе при переходах контент заметно «прыгает».
  static const screenH = lg;

  /// Скругления.
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;

  /// Минимальная цель нажатия по рекомендациям Apple. Ниже опускаться нельзя,
  /// даже если визуально элемент кажется меньше.
  static const minTapTarget = 44.0;
}
