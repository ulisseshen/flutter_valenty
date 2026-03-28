import 'package:valenty_test/valenty_test.dart';

import 'api_expenses_given_builder.dart';
import 'auth_given_builder.dart';
import 'budget_given_builder.dart';
import 'cached_expenses_given_builder.dart';
import 'clock_given_builder.dart';

/// GivenBuilder for the Expense feature.
///
/// Provides domain objects available in the Given phase:
/// - `.auth()` — configure authenticated user
/// - `.apiExpenses()` — configure what the API returns / enable POST
/// - `.budget()` — configure budget for a category
/// - `.cachedExpenses()` — pre-populate the local cache
/// - `.clock()` — override the clock with a fixed date
class ExpenseGivenBuilder extends GivenBuilder {
  ExpenseGivenBuilder(super.scenario);

  /// Configure authenticated user via AuthManager.
  AuthGivenBuilder auth() => AuthGivenBuilder(scenario);

  /// Configure API expense responses.
  ApiExpensesGivenBuilder apiExpenses() => ApiExpensesGivenBuilder(scenario);

  /// Configure budget for a category.
  BudgetGivenBuilder budget() => BudgetGivenBuilder(scenario);

  /// Pre-populate cached expenses.
  CachedExpensesGivenBuilder cachedExpenses() =>
      CachedExpensesGivenBuilder(scenario);

  /// Override the clock with a fixed date.
  ClockGivenBuilder clock() => ClockGivenBuilder(scenario);
}
