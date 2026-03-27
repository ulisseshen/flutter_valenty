import 'package:test/test.dart' as test_pkg;

import 'backend_stub_dsl.dart';
import 'system_dsl.dart';

/// Core test function for Valenty component tests.
///
/// Creates a [BackendStubDsl] and [SystemDsl] and passes them to the test body.
/// Setup runs before the body, teardown runs after (even on failure).
///
/// For Flutter projects, create a feature-specific wrapper that uses
/// `testWidgets` instead:
///
/// ```dart
/// void orderTest(
///   String description,
///   Future<void> Function(OrderSystemDsl, OrderBackendStub) body,
/// ) {
///   testWidgets(description, (tester) async {
///     final backend = OrderBackendStub();
///     final driver = OrderUiDriver(tester);
///     final system = OrderSystemDsl(driver);
///     backend.apply();
///     try {
///       await body(system, backend);
///     } finally {
///       backend.restore();
///     }
///   });
/// }
/// ```
void valentyTest<TSystem extends SystemDsl, TBackend extends BackendStubDsl>(
  String description, {
  required TBackend Function() createBackend,
  required TSystem Function(TBackend backend) createSystem,
  required Future<void> Function(TSystem system, TBackend backend) body,
}) {
  test_pkg.test(description, () async {
    final backend = createBackend();
    await backend.apply();
    try {
      final system = createSystem(backend);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
