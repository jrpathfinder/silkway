import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/app/flavor.dart';
import 'package:silkway_app/core/env/env.dart';

void main() {
  test('fromDartDefines falls back to defaults when no --dart-define values are supplied', () {
    final env = Env.fromDartDefines(AppFlavor.customer);
    expect(env.apiBaseUrl, 'http://localhost:3000');
    expect(env.useMocks, isTrue);
    expect(env.flavor, AppFlavor.customer);
  });

  test('fromDartDefines carries through the given flavor', () {
    final env = Env.fromDartDefines(AppFlavor.courier);
    expect(env.flavor, AppFlavor.courier);
  });
}
