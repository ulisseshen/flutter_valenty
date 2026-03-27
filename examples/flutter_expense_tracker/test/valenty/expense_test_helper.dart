import 'package:flutter_test/flutter_test.dart';

import 'dsl/expense_backend_stub.dart';
import 'dsl/expense_system_dsl.dart';
import 'dsl/expense_ui_driver.dart';

/// Valenty component test for the Expense Tracker app.
///
/// Sets up the full app with faked backend, provides domain-language
/// [system] DSL for user actions and [backend] DSL for stub configuration.
void valentyTest(
  String description,
  Future<void> Function(ExpenseSystemDsl system, ExpenseBackendStub backend)
      body,
) {
  testWidgets(description, (tester) async {
    final backend = ExpenseBackendStub();
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
