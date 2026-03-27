// =============================================================================
// FETCH EXPENSES ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Coupled Expense App — Fetch Expenses
//
// These scenarios test ExpenseScreenController.getExpenses() which:
// - Tries the API first, falls back to LocalStorage cache
// - Uses AuthManager.instance.currentUserId! for the API call
// - Saves successful API responses to LocalStorage
//
// QA Scenarios:
//
//   5. "Given the API returns 2 expenses for the current user,
//       when I fetch expenses,
//       then I should see 2 expenses with correct descriptions"
//
//   6. "Given the API fails with 503 AND cached expenses exist,
//       when I fetch expenses,
//       then I should see the cached expenses (fallback)"
//
//   7. "Given the API fails with 503 AND no cached expenses exist,
//       when I fetch expenses,
//       then I should see an empty list"
//
// =============================================================================

import 'package:test/test.dart';

import '../expense_scenario.dart';

void main() {
  group('Fetch Expenses', () {
    // --- Scenario 5: Fetch expenses from API ---------------------------------
    ExpenseScenario('should fetch expenses from API for current user')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withExpense(
              id: 'e1',
              description: 'Coffee',
              amount: 4.50,
              category: 'Food',
              userId: 'user-1',
            )
            .withExpense(
              id: 'e2',
              description: 'Uber',
              amount: 15.00,
              category: 'Transport',
              userId: 'user-1',
            )
        .when
        .fetchExpenses()
        .then
        .shouldSucceed()
        .and
        .expenseList()
            .hasCount(2)
            .containsExpense(description: 'Coffee')
            .containsExpense(description: 'Uber')
        .run();

    // --- Scenario 6: Fallback to cached expenses on API error ----------------
    ExpenseScenario('should fallback to cached expenses when API fails')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withApiError(503)
        .and
        .cachedExpenses()
            .withExpense(
              id: 'c1',
              description: 'Cached lunch',
              amount: 10.00,
              category: 'Food',
            )
        .when
        .fetchExpenses()
        .then
        .shouldSucceed()
        .and
        .expenseList()
            .hasCount(1)
            .containsExpense(description: 'Cached lunch')
        .run();

    // --- Scenario 7: Empty list when API fails and no cache ------------------
    ExpenseScenario('should return empty list when API fails and no cache')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withApiError(503)
        .when
        .fetchExpenses()
        .then
        .shouldSucceed()
        .and
        .expenseList()
            .isEmpty()
        .run();
  });
}
