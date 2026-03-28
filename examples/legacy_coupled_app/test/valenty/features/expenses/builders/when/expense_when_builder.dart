import 'package:valenty_test/valenty_test.dart';

import 'add_expense_when_builder.dart';
import 'fetch_expenses_when_builder.dart';
import 'get_spending_when_builder.dart';

/// WhenBuilder for the Expense feature.
///
/// Provides actions available in the When phase:
/// - `.addExpense()` — add a new expense
/// - `.fetchExpenses()` — fetch all expenses
/// - `.getSpending()` — get spending grouped by category
class ExpenseWhenBuilder extends WhenBuilder {
  ExpenseWhenBuilder(super.scenario);

  /// Trigger the "add expense" action.
  AddExpenseWhenBuilder addExpense() => AddExpenseWhenBuilder(scenario);

  /// Trigger the "fetch expenses" action.
  FetchExpensesWhenBuilder fetchExpenses() =>
      FetchExpensesWhenBuilder(scenario);

  /// Trigger the "get spending by category" action.
  GetSpendingWhenBuilder getSpending() => GetSpendingWhenBuilder(scenario);
}
