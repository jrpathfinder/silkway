import '../models/loyalty.dart';

/// No backend `loyalty` module exists yet — mock-only until that lands.
abstract class LoyaltyRepository {
  Future<List<LoyaltyPromotion>> listPromotions();
  Future<LoyaltyAccount> getAccount(String customerId);
}
