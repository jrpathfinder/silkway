import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/app/app.dart';
import 'package:silkway_app/app/flavor.dart';
import 'package:silkway_app/core/env/env.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('courier flavor boots straight to the courier home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(env: const Env(apiBaseUrl: 'http://localhost:3000', useMocks: true, flavor: AppFlavor.courier)),
        child: const SilkwayApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заказы'), findsOneWidget);
    expect(find.text('Пока нет предложений заказов'), findsOneWidget);
  });
}
