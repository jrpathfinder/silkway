/// No backend `notifications` module exists yet — this shape is client-first,
/// mock-only until push/SMS/email delivery is wired server-side.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
}
