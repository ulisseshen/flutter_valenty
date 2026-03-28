import 'package:valenty_test/valenty_test.dart';

import 'builders/given/order_given_builder.dart';

/// Entry point for Order feature acceptance tests.
///
/// Usage:
/// ```dart
/// OrderScenario('should calculate base price')
///     .given
///     .product()
///         .withUnitPrice(20.00)
///     .when
///     .placeOrder()
///         .withQuantity(5)
///     .then
///     .shouldSucceed();
/// ```
class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
  OrderScenario(super.description);

  @override
  OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return OrderGivenBuilder(scenario);
  }
}
