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
    // CourierRepositoryMock сеет пару готовых к выдаче заказов, чтобы флейвор
    // был проверяем и без бэкенда.
    expect(find.text('Новые предложения'), findsOneWidget);
    expect(find.textContaining('Красная площадь'), findsOneWidget);
  });
}
