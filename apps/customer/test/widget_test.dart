import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silkway_app/app/app.dart';
import 'package:silkway_app/app/flavor.dart';
import 'package:silkway_app/core/env/env.dart';
import 'package:silkway_app/core/providers.dart';

void main() {
  testWidgets('Customer app boots to the home screen against mocks', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(
            const Env(apiBaseUrl: 'http://localhost:3000', useMocks: true, flavor: AppFlavor.customer),
          ),
        ],
        child: const SilkwayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
