import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/design_system/widgets/dish_image.dart';

void main() {
  testWidgets('renders a placeholder icon when imageUrl is null', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DishImage(imageUrl: null))));

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('renders a bundled asset with the default cover fit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DishImage(imageUrl: 'assets/branding/dishes/plov.png'))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect((image.image as AssetImage).assetName, 'assets/branding/dishes/plov.png');
  });

  testWidgets('renders with a background color and custom fit when requested', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DishImage(
            imageUrl: 'assets/branding/dishes/plov.png',
            fit: BoxFit.contain,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(find.byType(Container), findsWidgets);
  });
}
