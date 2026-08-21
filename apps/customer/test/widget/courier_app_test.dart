import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/app/flavor.dart';
import 'package:silkway_app/core/env/env.dart';

import '../helpers/pump_helpers.dart';

void main() {
  testWidgets('courier flavor boots to the courier home screen', (tester) async {
    await pumpAppPastSplash(
      tester,
      env: const Env(apiBaseUrl: 'http://localhost:3000', useMocks: true, flavor: AppFlavor.courier),
    );

    expect(find.text('Заказы'), findsOneWidget);
    expect(find.text('Пока нет предложений заказов'), findsOneWidget);
  });
}
