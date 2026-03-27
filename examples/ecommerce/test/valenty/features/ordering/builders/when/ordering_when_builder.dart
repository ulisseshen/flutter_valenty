import 'package:valenty_dsl/valenty_dsl.dart';

import 'place_order_when_builder.dart';

/// WhenBuilder for the Ordering feature.
///
/// Provides use cases available in the When phase:
/// - `.placeOrder()` — place an order for products from the catalog
class OrderingWhenBuilder extends WhenBuilder {
  OrderingWhenBuilder(super.scenario);

  /// Trigger the "place order" use case.
  PlaceOrderWhenBuilder placeOrder() => PlaceOrderWhenBuilder(scenario);
}
