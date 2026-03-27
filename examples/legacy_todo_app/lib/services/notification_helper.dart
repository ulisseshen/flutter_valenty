import 'package:meta/meta.dart';

/// Static notification helper — typical legacy pattern.
///
/// In a real app: uses FlutterLocalNotificationsPlugin or Firebase Messaging.
/// ONE LINE ADDED for testing: @visibleForTesting sendFunction.
class NotificationHelper {
  /// @visibleForTesting — ONE LINE ADDED to enable testing.
  @visibleForTesting
  static void Function(String message) sendFunction = _defaultSend;

  static void _defaultSend(String message) {
    // In real app: FlutterLocalNotificationsPlugin().show(...)
    // ignore: avoid_print
    print('NOTIFICATION: $message');
  }

  /// Send a notification.
  static void send(String message) => sendFunction(message);

  /// Reset to default behavior — used in test tearDown.
  @visibleForTesting
  static void resetForTesting() {
    sendFunction = _defaultSend;
  }
}
