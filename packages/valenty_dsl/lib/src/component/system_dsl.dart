/// Base class for feature-specific system DSLs.
///
/// A SystemDsl provides user-facing actions and assertions in domain language.
/// Each feature creates a subclass with methods like `openApp()`, `login()`,
/// `addExpense()`, `verifyTotal()`.
///
/// ## Example
///
/// ```dart
/// class OrderSystemDsl extends SystemDsl {
///   OrderSystemDsl(this.driver);
///   final OrderUiDriver driver;
///
///   Future<void> openApp() async => driver.pumpApp();
///   Future<void> selectProduct(String sku) async => driver.tapProduct(sku);
///   Future<void> setQuantity(int qty) async => driver.enterQuantity(qty);
///   Future<void> placeOrder() async => driver.tapPlaceOrder();
///   Future<void> verifyTotal(String total) async => driver.verifyText(total);
/// }
/// ```
abstract class SystemDsl {
  const SystemDsl();
}
