// =============================================================================
// ORDER PLACEMENT ACCEPTANCE TESTS
// =============================================================================
//
// Domain: E-commerce Order Flow
//
// These scenarios demonstrate how an AI would generate fakes and acceptance
// tests for an e-commerce app in legacy code. Fakes replace real adapters
// (Firebase Firestore, HTTP API, LocalNotifications, SharedPreferences)
// so tests run against port interfaces only.
//
// QA Scenarios (plain English from QA team):
//
//   1. "Given a product Widget at $25 in the catalog,
//       when an order is placed for 4 units,
//       then the total should be $100 and status confirmed"
//
//   2. "Given products Widget at $10 and Gadget at $30,
//       when an order is placed for 2 Widgets and 1 Gadget,
//       then the total should be $50"
//
//   3. "Given a product in the catalog and the API is down,
//       when an order is placed,
//       then it should fail gracefully"
//
// =============================================================================

import 'package:test/test.dart';

import '../ordering_scenario.dart';

void main() {
  group('Order Placement', () {
    // ─── Scenario 1: Single product order ───────────────────────────────
    OrderingScenario('should calculate order total from catalog product')
        .given
        .catalog()
            .withProduct(id: 'P1', name: 'Widget', unitPrice: 25.00)
        .and
        .currency()
            .withCurrency('USD')
        .and
        .apiConfig()
            .withOrderApiSucceeding()
        .when
        .placeOrder()
            .withItem(productId: 'P1', quantity: 4)
        .then
        .shouldSucceed()
        .and
        .order()
            .hasTotalPrice(100.00)
            .hasStatus('confirmed')
        .run();

    // ─── Scenario 2: Multiple products order ────────────────────────────
    OrderingScenario('should calculate total for multiple products')
        .given
        .catalog()
            .withProduct(id: 'P1', name: 'Widget', unitPrice: 10.00)
        .and
        .catalog()
            .withProduct(id: 'P2', name: 'Gadget', unitPrice: 30.00)
        .and
        .apiConfig()
            .withOrderApiSucceeding()
        .when
        .placeOrder()
            .withItem(productId: 'P1', quantity: 2)
            .withItem(productId: 'P2', quantity: 1)
        .then
        .order()
            .hasTotalPrice(50.00)
        .run();

    // ─── Scenario 3: API failure ────────────────────────────────────────
    OrderingScenario('should handle API failure gracefully')
        .given
        .catalog()
            .withProduct(id: 'P1', name: 'Widget', unitPrice: 25.00)
        .and
        .apiConfig()
            .withOrderApiFailing(statusCode: 503, message: 'Service unavailable')
        .when
        .placeOrder()
            .withItem(productId: 'P1', quantity: 1)
        .then
        .shouldFail()
        .run();
  });
}
