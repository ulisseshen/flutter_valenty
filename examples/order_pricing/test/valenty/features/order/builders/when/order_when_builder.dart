import 'package:valenty_test/valenty_test.dart';

import 'place_order_when_builder.dart';

/// WhenBuilder for the Order feature.
///
/// Provides use cases available in the When phase:
/// - `.placeOrder()` — place an order for a product
class OrderWhenBuilder extends WhenBuilder {
  OrderWhenBuilder(super.scenario);

  /// Trigger the "place order" use case.
  PlaceOrderWhenBuilder placeOrder() => PlaceOrderWhenBuilder(scenario);
}
