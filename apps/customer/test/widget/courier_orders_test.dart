import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkway_app/core/models/order.dart';
import 'package:silkway_app/core/ports/courier_repository.dart';
import 'package:silkway_app/features/courier/presentation/courier_home_screen.dart';
import 'package:silkway_app/features/courier/presentation/providers/courier_providers.dart';

class _RecordingCourierRepository implements CourierRepository {
  _RecordingCourierRepository(this._offers);

  final List<Order> _offers;
  final List<String> accepted = [];
  final List<String> denied = [];

  @override
  Future<List<Order>> listOfferedOrders() async => _offers;

  @override
  Future<void> acceptOrder(String orderId) async => accepted.add(orderId);

  @override
  Future<void> denyOrder(String orderId) async => denied.add(orderId);
}

Order _order(String id) => Order(
      id: id,
      locationId: 'ca-moscow-1',
      customerId: '+79990000000',
      lines: const [OrderLine(itemId: 'plov-classic', name: 'Плов классический', quantity: 1, unitPriceRub: 590, modifierIds: [])],
      totalRub: 590,
      status: OrderStatus.paid,
      createdAt: DateTime(2026, 8, 19),
    );

Future<_RecordingCourierRepository> _pumpCourierHome(WidgetTester tester, List<Order> offers) async {
  final repo = _RecordingCourierRepository(offers);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [courierRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CourierHomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows an empty state when there are no offered orders', (tester) async {
    await _pumpCourierHome(tester, []);

    expect(find.text('Пока нет предложений заказов'), findsOneWidget);
  });

  testWidgets('lists offered orders with their totals', (tester) async {
    await _pumpCourierHome(tester, [_order('order-1'), _order('order-2')]);

    expect(find.text('Заказ order-1'), findsOneWidget);
    expect(find.text('Заказ order-2'), findsOneWidget);
    expect(find.text('590 ₽'), findsNWidgets(2));
  });

  testWidgets('accepting an offer calls the repository with that order id', (tester) async {
    final repo = await _pumpCourierHome(tester, [_order('order-1')]);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(repo.accepted, ['order-1']);
    expect(repo.denied, isEmpty);
  });

  testWidgets('denying an offer calls the repository with that order id', (tester) async {
    final repo = await _pumpCourierHome(tester, [_order('order-1')]);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(repo.denied, ['order-1']);
    expect(repo.accepted, isEmpty);
  });
}
