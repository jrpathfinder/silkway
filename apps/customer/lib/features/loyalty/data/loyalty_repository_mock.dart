import '../../../core/models/loyalty.dart';
import '../../../core/ports/loyalty_repository.dart';

/// Мок акций. Реального модуля лояльности на бэкенде нет.
class LoyaltyRepositoryMock implements LoyaltyRepository {
  @override
  Future<List<LoyaltyPromotion>> listPromotions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      LoyaltyPromotion(
        id: 'welcome-10',
        title: 'Скидка 10% на первый заказ',
        description: 'Действует при заказе от 1 000 ₽',
      ),
      LoyaltyPromotion(
        id: 'free-delivery',
        title: 'Бесплатная доставка от 1 500 ₽',
        description: 'Без промокода, применяется автоматически',
      ),
    ];
  }

  @override
  Future<LoyaltyAccount> getAccount(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const LoyaltyAccount(bonusPoints: 0);
  }
}
