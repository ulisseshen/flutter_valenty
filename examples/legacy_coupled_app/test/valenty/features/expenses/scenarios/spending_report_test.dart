// =============================================================================
// SPENDING REPORT ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Coupled Expense App — Spending Report
//
// These scenarios test ExpenseScreenController.getSpendingByCategory()
// which fetches expenses and groups them by category.
//
// QA Scenarios:
//
//  11. "Given the API returns expenses in Food and Transport,
//       when I get spending by category,
//       then Food should total 14.50 and Transport should total 15.00"
//
//  12. "Given the API returns no expenses,
//       when I get spending by category,
//       then the spending map should be empty"
//
// =============================================================================

import 'package:test/test.dart';

import '../expense_scenario.dart';

void main() {
  group('Spending Report', () {
    // --- Scenario 11: Group expenses by category with correct totals ---------
    ExpenseScenario('should group expenses by category with correct totals')
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
              description: 'Lunch',
              amount: 10.00,
              category: 'Food',
              userId: 'user-1',
            )
            .withExpense(
              id: 'e3',
              description: 'Uber',
              amount: 15.00,
              category: 'Transport',
              userId: 'user-1',
            )
        .when
        .getSpending()
        .then
        .shouldSucceed()
        .and
        .spending()
            .hasCategoryCount(2)
            .hasCategory('Food', 14.50)
            .hasCategory('Transport', 15.00)
        .run();

    // --- Scenario 12: Empty spending when no expenses exist ------------------
    ExpenseScenario('should return empty map when no expenses exist')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
        .when
        .getSpending()
        .then
        .shouldSucceed()
        .and
        .spending()
            .isEmpty()
        .run();
  });
}
