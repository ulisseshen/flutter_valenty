import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../../../../../lib/models/order.dart';
import 'order_assertion_builder.dart';

/// ThenBuilder for the Order feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the order succeeded
/// - `.shouldFail()` — assert the order failed
/// - `.order()` — fluent assertion builder for order properties
class OrderThenBuilder extends ThenBuilder {
  OrderThenBuilder(super.scenario);

  /// Assert the order placement succeeded.
  OrderThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isTrue, reason: 'Expected order to succeed');
    });
    return OrderThenTerminal(next);
  }

  /// Assert the order placement failed.
  OrderThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isFalse, reason: 'Expected order to fail');
    });
    return OrderThenTerminal(next);
  }

  /// Start a fluent assertion chain for the order.
  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class OrderThenTerminal {
  OrderThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  OrderAndThenBuilder get and => OrderAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Order feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class OrderAndThenBuilder extends AndThenBuilder {
  OrderAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for the order.
  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);
}
