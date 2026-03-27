// =============================================================================
// ORDER PRICING ACCEPTANCE TESTS
// =============================================================================
//
// QA Scenarios (plain English from QA team):
//
//   1. "Given a product with unit price $20,
//       when an order is placed with quantity 5,
//       then the order should succeed
//       and the base price should be $100"
//
//   2. "Given a product with unit price $20 and a coupon with 10% discount,
//       when an order is placed with quantity 5,
//       then the base price should be $90"
//
//   3. "Given a product with unit price $50,
//       when an order is placed with quantity 0,
//       then the order should fail"
//
// AI translated these scenarios into compile-time safe typed DSL below.
// No strings. No runtime failures. IDE guides every step.
// =============================================================================

import 'package:test/test.dart';

import '../order_scenario.dart';

void main() {
  group('Order Pricing', () {
    // ─── QA Scenario 1 ─────────────────────────────────────────────────
    // "Given a product with unit price $20,
    //  when an order is placed with quantity 5,
    //  then the order should succeed and the base price should be $100"
    //
    OrderScenario(
      'should calculate base price as product of unit price and quantity',
    )
        .given
        .product()
        .withUnitPrice(20.00)
        .when
        .placeOrder()
        .withQuantity(5)
        .then
        .shouldSucceed()
        .and
        .order()
        .hasBasePrice(100.00)
        .run();

    // ─── QA Scenario 2 ─────────────────────────────────────────────────
    // "Given a product with unit price $20 and a coupon with 10% discount,
    //  when an order is placed with quantity 5,
    //  then the base price should be $90"
    //
    OrderScenario('should apply percentage coupon to base price')
        .given
        .product()
        .withUnitPrice(20.00)
        .and
        .coupon()
        .withDiscount(0.10)
        .when
        .placeOrder()
        .withQuantity(5)
        .then
        .order()
        .hasBasePrice(90.00)
        .run();

    // ─── QA Scenario 3 ─────────────────────────────────────────────────
    // "Given a product with unit price $50,
    //  when an order is placed with quantity 0,
    //  then the order should fail"
    //
    OrderScenario('should reject order with zero quantity')
        .given
        .product()
        .withUnitPrice(50.00)
        .when
        .placeOrder()
        .withQuantity(0)
        .then
        .shouldFail()
        .run();
  });
}
