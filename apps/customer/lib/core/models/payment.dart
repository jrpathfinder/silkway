enum PaymentStatus { pending, succeeded, cancelled }

class PaymentCheckout {
  const PaymentCheckout({required this.id, required this.status, required this.confirmationUrl});

  final String id;
  final PaymentStatus status;
  final String confirmationUrl;

  factory PaymentCheckout.fromJson(Map<String, dynamic> json) => PaymentCheckout(
        id: json['id'] as String,
        status: PaymentStatus.values.byName(json['status'] as String),
        confirmationUrl: json['confirmationUrl'] as String,
      );
}
