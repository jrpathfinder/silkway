/// No backend `loyalty` module exists yet — this shape is client-first,
/// mock-only until a real endpoint is defined.
class LoyaltyPromotion {
  const LoyaltyPromotion({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
}

class LoyaltyAccount {
  const LoyaltyAccount({required this.bonusPoints});

  final int bonusPoints;
}
