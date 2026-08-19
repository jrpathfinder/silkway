import '../models/delivery.dart';

/// No backend `delivery` HTTP surface exists yet (the DeliveryProvider port
/// has no bound implementation) — mock-only until that lands.
abstract class DeliveryRepository {
  Future<DeliveryQuote> quote({required String locationId, required String addressId});
  Future<List<DeliveryTrackingPoint>> track(String orderId);
}
