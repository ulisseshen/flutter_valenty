import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../../../../../lib/models/order.dart';
import 'order_then_builder.dart';

/// Fluent assertion builder for Order properties.
///
/// Available assertions:
/// - `.hasBasePrice(double)` — assert the base price
/// - `.hasQuantity(int)` — assert the quantity
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class OrderAssertionBuilder extends AssertionBuilder {
  OrderAssertionBuilder(super.scenario);

  /// Assert the order has the expected base price.
  OrderAssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(
        order.basePrice,
        equals(expected),
        reason: 'Expected base price to be $expected',
      );
    });
    return this;
  }

  /// Assert the order has the expected quantity.
  OrderAssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(
        order.quantity,
        equals(expected),
        reason: 'Expected quantity to be $expected',
      );
    });
    return this;
  }

  /// Add more assertions.
  OrderAndThenBuilder get and => OrderAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
