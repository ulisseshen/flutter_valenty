import 'package:flutter_test/flutter_test.dart';

import 'dsl/expense_backend_stub.dart';
import 'dsl/expense_system_dsl.dart';
import 'dsl/expense_ui_driver.dart';

/// Valenty component test for the Expense Tracker app.
///
/// Sets up the full app with faked backend, provides domain-language
/// [system] DSL for user actions and [backend] DSL for stub configuration.
///
/// Use the optional [setup] parameter to configure the backend before
/// the test body runs. This keeps infrastructure visible next to the test.
///
/// ```dart
/// valentyTest(
///   'should show expenses',
///   setup: (backend) {
///     backend.stubExpenses([...]);
///   },
///   body: (system, backend) async {
///     await system.openApp();
///     await system.verifyExpenseVisible('Coffee');
///   },
/// );
/// ```
void valentyTest(
  String description, {
  void Function(ExpenseBackendStub backend)? setup,
  required Future<void> Function(
    ExpenseSystemDsl system,
    ExpenseBackendStub backend,
  ) body,
}) {
  testWidgets(description, (tester) async {
    final backend = ExpenseBackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = ExpenseUiDriver(tester);
      final system = ExpenseSystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
