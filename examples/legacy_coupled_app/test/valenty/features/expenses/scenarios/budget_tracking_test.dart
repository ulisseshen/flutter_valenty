// =============================================================================
// BUDGET TRACKING ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Coupled Expense App — Budget Tracking
//
// These scenarios test the budget warning logic embedded in
// ExpenseScreenController.addExpense(). After saving an expense,
// it checks if a budget exists for that category and warns if over budget.
//
// Anti-patterns being tested through:
// - Budget check logic coupled inside "widget" controller
// - NotificationService.showWarning() as static call, captured via override
// - LocalStorage.instance.getBudget() singleton access
//
// QA Scenarios:
//
//   8. "Given a budget of 100 for Food with 50 already spent,
//       when I add a 30 Food expense,
//       then no budget warning should be sent (20 remaining)"
//
//   9. "Given a budget of 100 for Food with 80 already spent,
//       when I add a 30 Food expense,
//       then a budget warning should be sent for Food"
//
//  10. "Given no budget is set for Transport,
//       when I add a Transport expense,
//       then no budget warning should be sent"
//
// =============================================================================

import 'package:test/test.dart';

import '../expense_scenario.dart';

void main() {
  group('Budget Tracking', () {
    // --- Scenario 8: Within budget — no warning ------------------------------
    ExpenseScenario('should not warn when expense is within budget')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .and
        .budget()
            .withBudget(category: 'Food', limit: 100, spent: 50)
        .when
        .addExpense()
            .withDescription('Snack')
            .withAmount(30)
            .withCategory('Food')
        .then
        .shouldSucceed()
        .and
        .budgetWarning()
            .wasNotSent()
        .run();

    // --- Scenario 9: Over budget — warning sent ------------------------------
    ExpenseScenario('should warn when expense exceeds remaining budget')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .and
        .budget()
            .withBudget(category: 'Food', limit: 100, spent: 80)
        .when
        .addExpense()
            .withDescription('Expensive dinner')
            .withAmount(30)
            .withCategory('Food')
        .then
        .shouldSucceed()
        .and
        .budgetWarning()
            .wasSent()
            .containsMessage('Over budget in Food!')
        .run();

    // --- Scenario 10: No budget set — no warning -----------------------------
    ExpenseScenario(
      'should skip budget check when no budget is set for category',
    )
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .when
        .addExpense()
            .withDescription('Bus ticket')
            .withAmount(2.50)
            .withCategory('Transport')
        .then
        .shouldSucceed()
        .and
        .budgetWarning()
            .wasNotSent()
        .run();
  });
}
