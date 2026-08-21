import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/utils/money.dart';

void main() {
  test('formatRub renders whole numbers with no decimals', () {
    expect(formatRub(590), '590 ₽');
  });

  test('formatRub renders fractional values with two decimals', () {
    expect(formatRub(199.5), '199.50 ₽');
  });

  test('formatRub renders zero as a whole number', () {
    expect(formatRub(0), '0 ₽');
  });
}
