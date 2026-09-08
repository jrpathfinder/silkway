import 'delivery.dart';

/// Сохранённый адрес доставки в адресной книге покупателя. Один из адресов
/// может быть отмечен как [isDefault] — им предзаполняется оформление заказа.
class SavedAddress {
  const SavedAddress({required this.id, required this.address, this.isDefault = false});

  final String id;
  final DeliveryAddress address;
  final bool isDefault;

  SavedAddress copyWith({DeliveryAddress? address, bool? isDefault}) => SavedAddress(
        id: id,
        address: address ?? this.address,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, dynamic> toJson() => {'id': id, 'address': address.toJson(), 'isDefault': isDefault};

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'] as String,
        address: DeliveryAddress.fromJson(json['address'] as Map<String, dynamic>),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
