import 'package:legacy_coupled_app_example/models/expense.dart';
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'expense_then_builder.dart';

/// Fluent assertion builder for expense list properties.
///
/// Available assertions:
/// - `.hasCount(int)` — assert the number of expenses
/// - `.containsExpense(description:)` — assert an expense exists
/// - `.isEmpty()` — assert the list is empty
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ExpenseListAssertionBuilder extends AssertionBuilder {
  ExpenseListAssertionBuilder(super.scenario);

  /// Assert the expense list has the expected number of items.
  ExpenseListAssertionBuilder hasCount(int expected) {
    addAssertionStep((ctx) {
      final expenses = ctx.get<List<Expense>>('expenseList');
      expect(
        expenses.length,
        equals(expected),
        reason: 'Expected $expected expenses, got ${expenses.length}',
      );
    });
    return this;
  }

  /// Assert the expense list contains an expense with the given description.
  ExpenseListAssertionBuilder containsExpense({required String description}) {
    addAssertionStep((ctx) {
      final expenses = ctx.get<List<Expense>>('expenseList');
      expect(
        expenses.any((e) => e.description == description),
        isTrue,
        reason:
            'Expected expense list to contain "$description"',
      );
    });
    return this;
  }

  /// Assert the expense list is empty.
  ExpenseListAssertionBuilder isEmpty() {
    addAssertionStep((ctx) {
      final expenses = ctx.get<List<Expense>>('expenseList');
      expect(
        expenses,
        hasLength(0),
        reason: 'Expected expense list to be empty',
      );
    });
    return this;
  }

  /// Add more assertions.
  ExpenseAndThenBuilder get and => ExpenseAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
