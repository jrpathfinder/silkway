import 'delivery.dart';

/// Заказ и его статус.
///
/// Статус на проводе приходит в SCREAMING_SNAKE_CASE, отсюда [fromWire].
enum OrderStatus {
  pendingPayment,
  paid,
  accepted,
  preparing,
  readyForDelivery,
  inDelivery,
  delivered,
  cancelled,
  refunded;

  static OrderStatus fromWire(String value) {
    switch (value) {
      case 'PENDING_PAYMENT':
        return OrderStatus.pendingPayment;
      case 'PAID':
        return OrderStatus.paid;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_DELIVERY':
        return OrderStatus.readyForDelivery;
      case 'IN_DELIVERY':
        return OrderStatus.inDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'REFUNDED':
        return OrderStatus.refunded;
      default:
        throw ArgumentError('Unknown order status: $value');
    }
  }
}

enum FulfillmentType {
  delivery,
  pickup;

  String toWire() => this == FulfillmentType.delivery ? 'DELIVERY' : 'PICKUP';

  static FulfillmentType fromWire(String? value) => value == 'PICKUP' ? FulfillmentType.pickup : FulfillmentType.delivery;
}

class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPriceRub,
    required this.modifierIds,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double unitPriceRub;
  final List<String> modifierIds;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        unitPriceRub: (json['unitPriceRub'] as num).toDouble(),
        modifierIds: (json['modifierIds'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.locationId,
    required this.customerId,
    required this.lines,
    required this.totalRub,
    required this.status,
    required this.createdAt,
    this.paymentId,
    this.fulfillmentType = FulfillmentType.delivery,
    this.deliveryAddress,
  });

  final String id;
  final String locationId;
  final String customerId;
  final List<OrderLine> lines;
  final double totalRub;
  final OrderStatus status;
  final DateTime createdAt;
  final String? paymentId;
  final FulfillmentType fulfillmentType;
  final DeliveryAddress? deliveryAddress;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        locationId: json['locationId'] as String,
        customerId: json['customerId'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map((l) => OrderLine.fromJson(l as Map<String, dynamic>))
            .toList(),
        totalRub: (json['totalRub'] as num).toDouble(),
        status: OrderStatus.fromWire(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        paymentId: json['paymentId'] as String?,
        fulfillmentType: FulfillmentType.fromWire(json['fulfillmentType'] as String?),
        deliveryAddress: json['deliveryAddress'] == null
            ? null
            : DeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>),
      );
}
