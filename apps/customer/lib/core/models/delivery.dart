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
