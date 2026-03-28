import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../setup/todo_test_environment.dart';
import 'todo_then_builder.dart';

/// Fluent assertion builder for notification assertions.
///
/// Available assertions:
/// - `.wasSent()` — assert at least one notification was sent
/// - `.wasNotSent()` — assert no notifications were sent
/// - `.containsMessage(String)` — assert a notification contains text
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class NotificationAssertionBuilder extends AssertionBuilder {
  NotificationAssertionBuilder(super.scenario);

  /// Assert at least one notification was sent.
  NotificationAssertionBuilder wasSent() {
    addAssertionStep((ctx) {
      final env = ctx.get<TodoTestEnvironment>('_testEnv');
      expect(
        env.capturedNotifications.wasSent,
        isTrue,
        reason: 'Expected at least one notification to be sent',
      );
    });
    return this;
  }

  /// Assert no notifications were sent.
  NotificationAssertionBuilder wasNotSent() {
    addAssertionStep((ctx) {
      final env = ctx.get<TodoTestEnvironment>('_testEnv');
      expect(
        env.capturedNotifications.wasSent,
        isFalse,
        reason: 'Expected no notifications to be sent',
      );
    });
    return this;
  }

  /// Assert a notification contains the given text.
  NotificationAssertionBuilder containsMessage(String substring) {
    addAssertionStep((ctx) {
      final env = ctx.get<TodoTestEnvironment>('_testEnv');
      expect(
        env.capturedNotifications.containsMessage(substring),
        isTrue,
        reason:
            'Expected a notification containing "$substring", '
            'got: ${env.capturedNotifications.messages}',
      );
    });
    return this;
  }

  /// Add more assertions.
  TodoAndThenBuilder get and => TodoAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
