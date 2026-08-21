import '../../../core/models/order.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/courier_repository.dart';

/// No backend courier-assignment HTTP surface exists yet — stub only, wired
/// once the backend adds it (see ADR-003).
class CourierRepositoryHttp implements CourierRepository {
  CourierRepositoryHttp(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<List<Order>> listOfferedOrders() => throw UnimplementedError('No backend courier endpoint yet.');

  @override
  Future<void> acceptOrder(String orderId) => throw UnimplementedError('No backend courier endpoint yet.');

  @override
  Future<void> denyOrder(String orderId) => throw UnimplementedError('No backend courier endpoint yet.');
}
