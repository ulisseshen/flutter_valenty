import 'package:test/test.dart' as test_pkg;

import 'backend_stub_dsl.dart';
import 'system_dsl.dart';

/// Core test function for Valenty component tests (pure Dart).
///
/// Creates a [BackendStubDsl] and [SystemDsl] and passes them to the test body.
/// Setup runs before the body, teardown runs after (even on failure).
///
/// ## With setup parameter
///
/// ```dart
/// valentyTest(
///   'should calculate total',
///   createBackend: OrderBackendStub.new,
///   createSystem: (backend) => OrderSystemDsl(backend),
///   setup: (backend) {
///     backend.stubProduct(price: 20.00);
///   },
///   body: (system, backend) async {
///     system.placeOrder(quantity: 5);
///     system.verifyTotal(100.00);
///   },
/// );
/// ```
///
/// ## For Flutter projects
///
/// Create a project-level `valentyTest` wrapper using `testWidgets`:
///
/// ```dart
/// void valentyTest(
///   String description, {
///   void Function(MyBackendStub backend)? setup,
///   required Future<void> Function(MySystemDsl, MyBackendStub) body,
/// }) {
///   testWidgets(description, (tester) async {
///     final backend = MyBackendStub();
///     if (setup != null) setup(backend);
///     await backend.apply();
///     try {
///       final driver = MyUiDriver(tester);
///       final system = MySystemDsl(driver);
///       await body(system, backend);
///     } finally {
///       await backend.restore();
///     }
///   });
/// }
/// ```
void valentyTest<TSystem extends SystemDsl, TBackend extends BackendStubDsl>(
  String description, {
  required TBackend Function() createBackend,
  required TSystem Function(TBackend backend) createSystem,
  void Function(TBackend backend)? setup,
  required Future<void> Function(TSystem system, TBackend backend) body,
}) {
  test_pkg.test(description, () async {
    final backend = createBackend();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final system = createSystem(backend);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
