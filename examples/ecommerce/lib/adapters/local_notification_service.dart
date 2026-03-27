import '../models/notification_payload.dart';
import '../ports/notification_port.dart';

/// Adapter that implements [NotificationPort] using local notifications.
///
/// In a real Flutter project, this class would depend on the
/// `flutter_local_notifications` package. Since this is a pure Dart example
/// (no Flutter SDK), we provide an in-memory implementation with console
/// output that demonstrates the pattern.
///
/// ## Real Flutter implementation sketch
///
/// ```dart
/// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
///
/// class LocalNotificationService implements NotificationPort {
///   final FlutterLocalNotificationsPlugin _plugin;
///   int _nextId = 0;
///
///   LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
///       : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
///     _plugin.initialize(
///       const InitializationSettings(
///         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
///         iOS: DarwinInitializationSettings(),
///       ),
///     );
///   }
///
///   @override
///   Future<void> show(NotificationPayload payload) async {
///     await _plugin.show(
///       _nextId++,
///       payload.title,
///       payload.body,
///       const NotificationDetails(
///         android: AndroidNotificationDetails(
///           'ecommerce_channel',
///           'E-Commerce',
///           importance: Importance.high,
///         ),
///         iOS: DarwinNotificationDetails(),
///       ),
///       payload: jsonEncode(payload.data),
///     );
///   }
///
///   @override
///   Future<List<NotificationPayload>> getPending() async {
///     final pending = await _plugin.pendingNotificationRequests();
///     return pending.map((r) => NotificationPayload(
///       title: r.title ?? '',
///       body: r.body ?? '',
///     )).toList();
///   }
/// }
/// ```
class LocalNotificationService implements NotificationPort {
  LocalNotificationService();

  /// In-memory store simulating the OS notification tray.
  final List<NotificationPayload> _pending = [];

  @override
  Future<void> show(NotificationPayload payload) async {
    // In real implementation: _plugin.show(id, title, body, details)
    _pending.add(payload);

    // Console output so the adapter visibly "does something" in pure Dart.
    // ignore: avoid_print
    print('[Notification] ${payload.title}: ${payload.body}');
  }

  @override
  Future<List<NotificationPayload>> getPending() async {
    // In real implementation: _plugin.pendingNotificationRequests()
    return List.unmodifiable(_pending);
  }
}
