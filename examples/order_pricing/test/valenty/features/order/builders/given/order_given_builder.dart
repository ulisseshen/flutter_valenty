import 'package:valenty_test/valenty_test.dart';

import 'product_given_builder.dart';
import 'coupon_given_builder.dart';

/// GivenBuilder for the Order feature.
///
/// Provides domain objects available in the Given phase:
/// - `.product()` — set up a product with price, name
/// - `.coupon()` — set up a discount coupon
class OrderGivenBuilder extends GivenBuilder {
  OrderGivenBuilder(super.scenario);

  /// Set up a product in the test context.
  ProductGivenBuilder product() => ProductGivenBuilder(scenario);

  /// Set up a coupon in the test context.
  CouponGivenBuilder coupon() => CouponGivenBuilder(scenario);
}
