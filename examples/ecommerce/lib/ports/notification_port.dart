import '../models/notification_payload.dart';

/// Port for showing local notifications (backed by LocalNotifications plugin).
abstract class NotificationPort {
  Future<void> show(NotificationPayload payload);
  Future<List<NotificationPayload>> getPending();
}
