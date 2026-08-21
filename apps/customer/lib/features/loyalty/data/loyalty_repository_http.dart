import '../../../core/models/loyalty.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ports/loyalty_repository.dart';

/// No backend `loyalty` module exists yet — stub only (see ADR-003).
class LoyaltyRepositoryHttp implements LoyaltyRepository {
  LoyaltyRepositoryHttp(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<List<LoyaltyPromotion>> listPromotions() => throw UnimplementedError('No backend loyalty endpoint yet.');

  @override
  Future<LoyaltyAccount> getAccount(String customerId) =>
      throw UnimplementedError('No backend loyalty endpoint yet.');
}
