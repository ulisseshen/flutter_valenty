import 'package:ecommerce_example/models/order.dart';
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'ordering_then_builder.dart';

/// Fluent assertion builder for Order properties.
///
/// Available assertions:
/// - `.hasTotalPrice(double)` — assert the total price
/// - `.hasTaxAmount(double)` — assert the tax amount
/// - `.hasStatus(String)` — assert the order status
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class OrderAssertionBuilder extends AssertionBuilder {
  OrderAssertionBuilder(super.scenario);

  /// Assert the order has the expected total price.
  OrderAssertionBuilder hasTotalPrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(
        order.totalPrice,
        equals(expected),
        reason: 'Expected total price to be $expected',
      );
    });
    return this;
  }

  /// Assert the order has the expected tax amount.
  OrderAssertionBuilder hasTaxAmount(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(
        order.taxAmount,
        equals(expected),
        reason: 'Expected tax amount to be $expected',
      );
    });
    return this;
  }

  /// Assert the order has the expected status.
  OrderAssertionBuilder hasStatus(String expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(
        order.status,
        equals(expected),
        reason: 'Expected status to be "$expected"',
      );
    });
    return this;
  }

  /// Add more assertions.
  OrderingAndThenBuilder get and => OrderingAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
