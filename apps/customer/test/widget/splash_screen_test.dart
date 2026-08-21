import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/features/splash/presentation/splash_screen.dart';

/// video_player has no implementation under `flutter test`, so these cover
/// the paths that must work regardless of what the video does — the splash
/// must never trap the user before they reach the app.
void main() {
  testWidgets('tapping the splash finishes it immediately', (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onFinished: () => finished++)));
    await tester.pump();

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished, 1);
  });

  testWidgets('finishes at most once even if tapped repeatedly', (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onFinished: () => finished++)));
    await tester.pump();

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished, 1);
  });

  testWidgets('shows the native-splash still frame until the video is ready', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onFinished: () {})));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/branding/splash.png');

    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();
  });

  testWidgets('the failsafe timer finishes the splash if the video never completes', (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onFinished: () => finished++)));
    await tester.pump();
    expect(finished, 0);

    await tester.pump(SplashScreen.maxDuration + const Duration(seconds: 1));

    expect(finished, 1);
  });
}
