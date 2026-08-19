/// Formats `priceRub` (float rubles, as sent by the API) for display.
/// Deliberately does no minor-unit (kopeck) math client-side — the backend
/// already converts price_minor -> priceRub server-side; the client only
/// ever sees and displays rubles.
String formatRub(double priceRub) {
  final isWhole = priceRub == priceRub.roundToDouble();
  final value = isWhole ? priceRub.toStringAsFixed(0) : priceRub.toStringAsFixed(2);
  return '$value ₽';
}
