import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'budget_warning_assertion_builder.dart';
import 'expense_assertion_builder.dart';
import 'expense_list_assertion_builder.dart';
import 'spending_assertion_builder.dart';

/// ThenBuilder for the Expense feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the operation succeeded
/// - `.shouldFail()` — assert the operation failed
/// - `.shouldFailWith(substring)` — assert the error contains text
/// - `.expenseList()` — fluent assertions on the expense list
/// - `.expense()` — fluent assertions on a single expense
/// - `.budgetWarning()` — fluent assertions on budget warnings
/// - `.spending()` — fluent assertions on spending map
class ExpenseThenBuilder extends ThenBuilder {
  ExpenseThenBuilder(super.scenario);

  /// Assert the operation succeeded.
  ExpenseThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final failed = ctx.has('operationFailed')
          ? ctx.get<bool>('operationFailed')
          : false;
      expect(failed, isFalse, reason: 'Expected operation to succeed');
    });
    return ExpenseThenTerminal(next);
  }

  /// Assert the operation failed.
  ExpenseThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('operationFailed');
      expect(failed, isTrue, reason: 'Expected operation to fail');
    });
    return ExpenseThenTerminal(next);
  }

  /// Assert the operation failed with an error containing [substring].
  ExpenseThenTerminal shouldFailWith(String substring) {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('operationFailed');
      expect(failed, isTrue, reason: 'Expected operation to fail');
      final error = ctx.get<String>('operationError');
      expect(
        error,
        contains(substring),
        reason: 'Expected error to contain "$substring", got: $error',
      );
    });
    return ExpenseThenTerminal(next);
  }

  /// Start a fluent assertion chain for the expense list.
  ExpenseListAssertionBuilder expenseList() =>
      ExpenseListAssertionBuilder(scenario);

  /// Start a fluent assertion chain for a stored expense.
  ExpenseAssertionBuilder expense() => ExpenseAssertionBuilder(scenario);

  /// Start a fluent assertion chain for budget warnings.
  BudgetWarningAssertionBuilder budgetWarning() =>
      BudgetWarningAssertionBuilder(scenario);

  /// Start a fluent assertion chain for spending map.
  SpendingAssertionBuilder spending() => SpendingAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ExpenseThenTerminal {
  ExpenseThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  ExpenseAndThenBuilder get and => ExpenseAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Expense feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class ExpenseAndThenBuilder extends AndThenBuilder {
  ExpenseAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for the expense list.
  ExpenseListAssertionBuilder expenseList() =>
      ExpenseListAssertionBuilder(scenario);

  /// Start a fluent assertion chain for a stored expense.
  ExpenseAssertionBuilder expense() => ExpenseAssertionBuilder(scenario);

  /// Start a fluent assertion chain for budget warnings.
  BudgetWarningAssertionBuilder budgetWarning() =>
      BudgetWarningAssertionBuilder(scenario);

  /// Start a fluent assertion chain for spending map.
  SpendingAssertionBuilder spending() => SpendingAssertionBuilder(scenario);
}
