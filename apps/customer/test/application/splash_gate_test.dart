import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/splash/application/splash_gate.dart';

import '../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 8, 21, 12);

  test('на первом запуске заставка показывается', () async {
    final gate = SplashGate(FakeLocalKv());
    expect(await gate.shouldShow(now: now), isTrue);
  });

  test('сразу после показа заставка пропускается', () async {
    final kv = FakeLocalKv();
    final gate = SplashGate(kv);
    await gate.markShown(now: now);

    expect(await gate.shouldShow(now: now.add(const Duration(minutes: 5))), isFalse);
  });

  test('незадолго до истечения интервала всё ещё пропускается', () async {
    final gate = SplashGate(FakeLocalKv());
    await gate.markShown(now: now);

    final justBefore = now.add(SplashGate.interval - const Duration(minutes: 1));
    expect(await gate.shouldShow(now: justBefore), isFalse);
  });

  test('по истечении интервала показывается снова', () async {
    final gate = SplashGate(FakeLocalKv());
    await gate.markShown(now: now);

    expect(await gate.shouldShow(now: now.add(SplashGate.interval)), isTrue);
  });

  test('испорченное значение в хранилище не ломает запуск', () async {
    final kv = FakeLocalKv();
    await kv.setString(SplashGate.storageKey, 'не дата');

    expect(await SplashGate(kv).shouldShow(now: now), isTrue);
  });

  test('переведённые назад часы не прячут заставку навсегда', () async {
    final gate = SplashGate(FakeLocalKv());
    await gate.markShown(now: now);

    // Пользователь перевёл часы на сутки назад: разница отрицательная.
    expect(await gate.shouldShow(now: now.subtract(const Duration(days: 1))), isTrue);
  });
}
