import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_kv.dart';

/// Решает, показывать ли заставку на этом запуске.
///
/// Заставка — брендовый момент, но смотреть её при каждом холодном старте
/// незачем: iOS регулярно выгружает приложение из памяти, и пользователь,
/// открывающий меню несколько раз за день, каждый раз ждал бы лишние ~2
/// секунды. Поэтому ролик показывается не чаще раза в [interval]: первый
/// запуск за день — с заставкой, остальные открывают меню сразу.
///
/// Речь именно о повторных ХОЛОДНЫХ запусках. Возврат из фона заставку и так
/// не проигрывает: Flutter не перезапускается и состояние сохраняется.
class SplashGate {
  SplashGate(this._kv);

  final LocalKv _kv;

  static const storageKey = 'splash_last_shown_at';

  /// Как часто заставка имеет право появляться.
  static const interval = Duration(hours: 6);

  Future<bool> shouldShow({DateTime? now}) async {
    final raw = await _kv.getString(storageKey);
    if (raw == null) return true;

    final last = DateTime.tryParse(raw);
    // Значение испорчено (ручная правка, смена формата) — не молчим об этом
    // отказом показывать, а ведём себя как при первом запуске.
    if (last == null) return true;

    final elapsed = (now ?? DateTime.now()).difference(last);
    // Отрицательное — часы на устройстве перевели назад. Иначе заставка могла
    // бы пропасть на неопределённый срок.
    if (elapsed.isNegative) return true;

    return elapsed >= interval;
  }

  Future<void> markShown({DateTime? now}) =>
      _kv.setString(storageKey, (now ?? DateTime.now()).toIso8601String());
}

/// Решение принимается один раз при старте (см. runSilkwayApp) и передаётся
/// сюда переопределением: роутер выбирает стартовый маршрут синхронно, а
/// чтение хранилища асинхронное.
final showSplashProvider = Provider<bool>((ref) {
  throw UnimplementedError('showSplashProvider должен быть переопределён в runSilkwayApp');
});
