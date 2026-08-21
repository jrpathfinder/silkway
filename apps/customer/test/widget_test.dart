import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_helpers.dart';

void main() {
  testWidgets('Customer app boots to the home screen against mocks', (WidgetTester tester) async {
    await pumpAppPastSplash(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
