import '../models/notification.dart';

/// No backend `notifications` module exists yet — mock-only until that lands.
abstract class NotificationsRepository {
  Future<List<AppNotification>> list();
  Future<void> registerPushToken(String token);
}
