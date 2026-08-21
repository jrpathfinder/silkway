import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/splash/presentation/splash_screen.dart';

/// Заставка не имеет права заблокировать вход в приложение, поэтому основное
/// здесь — все пути выхода, а не красота анимации.
void main() {
  /// Строит экран и возвращает счётчик срабатываний onFinished.
  Future<int Function()> pumpSplash(WidgetTester tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onFinished: () => finished++)));
    await tester.pump();
    return () => finished;
  }

  testWidgets('заставка завершается сама по окончании анимации', (tester) async {
    final finished = await pumpSplash(tester);
    expect(finished(), 0);

    await tester.pump(SplashScreen.duration + const Duration(milliseconds: 200));

    expect(finished(), 1);
  });

  testWidgets('тап пропускает заставку немедленно', (tester) async {
    final finished = await pumpSplash(tester);

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished(), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('заставка завершается ровно один раз, сколько по ней ни тапай', (tester) async {
    final finished = await pumpSplash(tester);

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    // И анимация не должна довызвать колбэк повторно.
    await tester.pump(SplashScreen.duration + const Duration(milliseconds: 200));

    expect(finished(), 1);
  });

  testWidgets('показывает обе сцены, первой — ту же, что нативная заставка', (tester) async {
    await pumpSplash(tester);

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final names = images.map((i) => (i.image as AssetImage).assetName).toList();

    // Порядок важен: шёлк снизу, чайхана проявляется поверх него. Путь первой
    // сцены должен совпадать с pubspec.yaml (flutter_native_splash), иначе
    // кадр дёрнется при передаче управления от нативной заставки.
    expect(names, [SplashScreen.silkAsset, SplashScreen.teahouseAsset]);
    expect(images.every((i) => i.fit == BoxFit.cover), isTrue);

    await tester.pumpAndSettle();
  });

  testWidgets('чайхана проявляется поверх шёлка к концу заставки', (tester) async {
    await pumpSplash(tester);

    double teahouseOpacity() => tester.widget<FadeTransition>(find.byKey(SplashScreen.fadeKey)).opacity.value;

    // В самом начале видна только шторка.
    expect(teahouseOpacity(), closeTo(0, 0.001));

    await tester.pump(SplashScreen.duration * SplashScreen.fadeEnd);
    expect(teahouseOpacity(), closeTo(1, 0.05));

    await tester.pumpAndSettle();
  });

  testWidgets('картинка увеличивается со временем', (tester) async {
    await pumpSplash(tester);

    double scaleNow() => tester.widget<Transform>(find.byKey(SplashScreen.zoomKey)).transform.getMaxScaleOnAxis();
    final start = scaleNow();
    await tester.pump(const Duration(milliseconds: 900));
    final mid = scaleNow();

    expect(start, closeTo(1.0, 0.001));
    expect(mid, greaterThan(start));
    await tester.pumpAndSettle();
  });
}
