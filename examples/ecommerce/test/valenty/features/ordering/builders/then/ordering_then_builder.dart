import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'notification_assertion_builder.dart';
import 'order_assertion_builder.dart';

/// ThenBuilder for the Ordering feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the order placement succeeded
/// - `.shouldFail()` — assert the order placement failed
/// - `.order()` — fluent assertion builder for order properties
/// - `.notification()` — fluent assertion builder for notifications
class OrderingThenBuilder extends ThenBuilder {
  OrderingThenBuilder(super.scenario);

  /// Assert the order placement succeeded.
  OrderingThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('orderFailed');
      expect(failed, isFalse, reason: 'Expected order to succeed');
    });
    return OrderingThenTerminal(next);
  }

  /// Assert the order placement failed.
  OrderingThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('orderFailed');
      expect(failed, isTrue, reason: 'Expected order to fail');
    });
    return OrderingThenTerminal(next);
  }

  /// Start a fluent assertion chain for the order.
  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);

  /// Start a fluent assertion chain for notifications.
  NotificationAssertionBuilder notification() =>
      NotificationAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class OrderingThenTerminal {
  OrderingThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  OrderingAndThenBuilder get and => OrderingAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Ordering feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class OrderingAndThenBuilder extends AndThenBuilder {
  OrderingAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for the order.
  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);

  /// Start a fluent assertion chain for notifications.
  NotificationAssertionBuilder notification() =>
      NotificationAssertionBuilder(scenario);
}
