import 'package:valenty_dsl/valenty_dsl.dart';

import 'builders/given/ordering_given_builder.dart';

/// Entry point for Ordering feature acceptance tests.
///
/// Usage:
/// ```dart
/// OrderingScenario('should calculate order total from catalog product')
///     .given
///     .catalog()
///         .withProduct(id: 'P1', name: 'Widget', unitPrice: 25.00)
///     .and
///     .apiConfig()
///         .withOrderApiSucceeding()
///     .when
///     .placeOrder()
///         .withItem(productId: 'P1', quantity: 4)
///     .then
///     .shouldSucceed()
///     .and
///     .order()
///         .hasTotalPrice(100.00)
///     .run();
/// ```
class OrderingScenario extends FeatureScenario<OrderingGivenBuilder> {
  OrderingScenario(super.description);

  @override
  OrderingGivenBuilder createGivenBuilder(
    ScenarioBuilder<NeedsWhen> scenario,
  ) {
    return OrderingGivenBuilder(scenario);
  }
}
