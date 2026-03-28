/// Base class for feature-specific backend stub DSLs.
///
/// A BackendStubDsl configures fakes and manages singleton factory overrides
/// using `@visibleForTesting` factories.
///
/// ## Example
///
/// ```dart
/// class OrderBackendStub extends BackendStubDsl {
///   final FakeHttpClient fakeHttp = FakeHttpClient();
///   final List<String> capturedNotifications = [];
///
///   void stubProduct({required String sku, required double price}) {
///     fakeHttp.stubGet('/api/products/$sku', {'sku': sku, 'price': price});
///   }
///
///   void stubOrderCreation({required double totalPrice}) {
///     fakeHttp.stubPost('/api/orders', {'totalPrice': totalPrice});
///   }
///
///   @override
///   Future<void> apply() async {
///     OrderService.httpFactory = () => fakeHttp;
///     NotificationService.sendFn = (msg) => capturedNotifications.add(msg);
///   }
///
///   @override
///   Future<void> restore() async {
///     OrderService.httpFactory = () => RealHttpClient();
///     NotificationService.resetForTesting();
///   }
/// }
/// ```
abstract class BackendStubDsl {
  const BackendStubDsl();

  /// Apply singleton factory overrides with fakes.
  ///
  /// Called before the test body runs.
  Future<void> apply();

  /// Restore original singleton factories.
  ///
  /// Called after the test body runs (even on failure).
  Future<void> restore();
}
