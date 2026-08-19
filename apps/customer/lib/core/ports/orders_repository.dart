import '../models/order.dart';

class CreateOrderLineInput {
  const CreateOrderLineInput({required this.itemId, required this.quantity, this.modifierIds = const []});

  final String itemId;
  final int quantity;
  final List<String> modifierIds;
}

abstract class OrdersRepository {
  Future<Order> create({
    required String locationId,
    required String customerId,
    required List<CreateOrderLineInput> lines,
    required String idempotencyKey,
  });

  Future<Order> getById(String orderId);

  /// No backend route exists yet for listing a customer's orders
  /// (`OrdersService.listForCustomer` is never wired to a controller route in
  /// orders.controller.ts) — mock-only until that lands.
  Future<List<Order>> listForCustomer(String customerId);
}
