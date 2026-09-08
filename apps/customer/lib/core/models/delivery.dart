/// No backend `delivery` HTTP surface exists yet (the DeliveryProvider port
/// has no bound implementation server-side) — this shape is a client-first
/// best guess, to be reconciled once the backend module lands.
class DeliveryQuote {
  const DeliveryQuote({
    required this.zoneId,
    required this.priceRub,
    required this.minOrderRub,
    required this.etaMinutes,
  });

  final String zoneId;
  final double priceRub;
  final double minOrderRub;
  final int etaMinutes;
}

class DeliveryTrackingPoint {
  const DeliveryTrackingPoint({required this.lat, required this.lng, required this.label});

  final double lat;
  final double lng;
  final String label;
}

/// Адрес доставки, выбранный на карте при оформлении заказа. Сохранение
/// между заказами — отдельная сущность [SavedAddress] (адресная книга),
/// см. `features/profile/application/saved_addresses_notifier.dart`.
class DeliveryAddress {
  const DeliveryAddress({required this.lat, required this.lng, required this.addressText, this.comment});

  final double lat;
  final double lng;
  final String addressText;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'addressText': addressText,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        addressText: json['addressText'] as String,
        comment: json['comment'] as String?,
      );
}
