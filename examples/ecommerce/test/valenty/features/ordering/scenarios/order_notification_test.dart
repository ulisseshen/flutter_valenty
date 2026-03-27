// =============================================================================
// ORDER NOTIFICATION ACCEPTANCE TESTS
// =============================================================================
//
// Domain: E-commerce Order Flow — Notification side-effects
//
// These scenarios verify that the notification port receives the correct
// payloads after a successful order placement. The fake notification
// service stores all sent notifications in memory so the Then phase can
// inspect them.
//
// QA Scenario:
//   "Given a product Widget at $25 in the catalog,
//    when an order is placed for 2 units,
//    then a notification with title 'Order Confirmed' should appear
//    and the notification body should contain the total '50.00'"
//
// =============================================================================

import 'package:test/test.dart';

import '../ordering_scenario.dart';

void main() {
  group('Order Notifications', () {
    // ─── Scenario: Notification after successful order ──────────────────
    OrderingScenario('should send notification after successful order')
        .given
        .catalog()
            .withProduct(id: 'P1', name: 'Widget', unitPrice: 25.00)
        .and
        .apiConfig()
            .withOrderApiSucceeding()
        .when
        .placeOrder()
            .withItem(productId: 'P1', quantity: 2)
        .then
        .shouldSucceed()
        .and
        .notification()
            .hasNotification(title: 'Order Confirmed')
            .notificationContains('50.00')
        .run();
  });
}
