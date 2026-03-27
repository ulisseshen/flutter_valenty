import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../fakes/fake_notification_service.dart';
import 'ordering_then_builder.dart';

/// Fluent assertion builder for notification verification.
///
/// Available assertions:
/// - `.hasNotification({title})` — assert a notification with the given title was sent
/// - `.notificationContains(String)` — assert a notification body contains text
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class NotificationAssertionBuilder extends AssertionBuilder {
  NotificationAssertionBuilder(super.scenario);

  /// Assert a notification with the given title was sent.
  NotificationAssertionBuilder hasNotification({required String title}) {
    addAssertionStep((ctx) {
      final service = ctx.get<FakeNotificationService>('notificationService');
      final notifications = service.sentNotifications;
      final hasTitle = notifications.any((n) => n.title == title);
      expect(
        hasTitle,
        isTrue,
        reason: 'Expected a notification with title "$title", '
            'but got: ${notifications.map((n) => n.title).toList()}',
      );
    });
    return this;
  }

  /// Assert any notification body contains the given text.
  NotificationAssertionBuilder notificationContains(String text) {
    addAssertionStep((ctx) {
      final service = ctx.get<FakeNotificationService>('notificationService');
      final notifications = service.sentNotifications;
      final hasText = notifications.any((n) => n.body.contains(text));
      expect(
        hasText,
        isTrue,
        reason: 'Expected a notification body containing "$text", '
            'but got: ${notifications.map((n) => n.body).toList()}',
      );
    });
    return this;
  }

  /// Add more assertions.
  OrderingAndThenBuilder get and => OrderingAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
