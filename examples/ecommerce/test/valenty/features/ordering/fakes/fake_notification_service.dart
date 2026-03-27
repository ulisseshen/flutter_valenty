import 'package:ecommerce_example/models/notification_payload.dart';
import 'package:ecommerce_example/ports/notification_port.dart';

/// In-memory fake for NotificationPort (replaces LocalNotifications plugin).
///
/// Stores all sent notifications in a list so the Then phase can verify them.
class FakeNotificationService implements NotificationPort {
  final List<NotificationPayload> _sent = [];

  List<NotificationPayload> get sentNotifications =>
      List.unmodifiable(_sent);

  @override
  Future<void> show(NotificationPayload payload) async {
    _sent.add(payload);
  }

  @override
  Future<List<NotificationPayload>> getPending() async {
    return List.unmodifiable(_sent);
  }
}
