// =============================================================================
// ADD EXPENSE ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Coupled Expense App — Add Expense
//
// These scenarios test ExpenseScreenController.addExpense() through the REAL
// singleton with FAKE dependencies injected via @visibleForTesting factories.
//
// Anti-patterns being tested through:
// - Business logic in "widget" controller (validation + API + storage + budget)
// - Static chain: AuthManager.instance.currentUserId!
// - Hardcoded clock replaced by clockFactory()
// - NotificationService.showWarning() captured via showWarningFn override
//
// QA Scenarios:
//
//   1. "Given a logged-in user AND POST is enabled,
//       when I add an expense with description 'Coffee' and amount 4.50,
//       then the expense should be stored with correct amount and category"
//
//   2. "Given a user logged in as 'user-42',
//       when I add an expense,
//       then the stored expense should have userId 'user-42'"
//
//   3. "Given a fixed clock at 2024-01-15 08:00,
//       when I add an expense,
//       then the stored expense should have that exact date"
//
//   4. "Given a logged-in user,
//       when I add an expense with amount 0,
//       then it should fail with 'Amount must be positive'"
//
// =============================================================================

import 'package:test/test.dart';

import '../expense_scenario.dart';

void main() {
  group('Add Expense', () {
    // --- Scenario 1: Add expense with correct amount and category ------------
    ExpenseScenario('should add expense with correct amount and category')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .when
        .addExpense()
            .withDescription('Coffee')
            .withAmount(4.50)
            .withCategory('Food')
        .then
        .shouldSucceed()
        .and
        .expense()
            .hasDescription('Coffee')
            .hasAmount(4.50)
            .hasCategory('Food')
        .run();

    // --- Scenario 2: Uses current user ID from AuthManager -------------------
    ExpenseScenario('should use current user ID from AuthManager')
        .given
        .auth()
            .asUser('user-42', 'user42@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .when
        .addExpense()
            .withDescription('Lunch')
            .withAmount(12.00)
            .withCategory('Food')
        .then
        .shouldSucceed()
        .and
        .expense()
            .hasUserId('user-42')
        .run();

    // --- Scenario 3: Uses fixed date from clock factory ----------------------
    ExpenseScenario('should use fixed date from clock factory')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .clock()
            .withFixedDate(DateTime(2024, 1, 15, 8, 0))
        .and
        .apiExpenses()
            .withPostEnabled()
        .when
        .addExpense()
            .withDescription('Taxi')
            .withAmount(25.00)
            .withCategory('Transport')
        .then
        .shouldSucceed()
        .and
        .expense()
            .hasDate(DateTime(2024, 1, 15, 8, 0))
        .run();

    // --- Scenario 4: Rejects expense with zero amount ------------------------
    ExpenseScenario('should reject expense with zero amount')
        .given
        .auth()
            .asUser('user-1', 'user@test.com')
        .and
        .apiExpenses()
            .withPostEnabled()
        .when
        .addExpense()
            .withDescription('Nothing')
            .withAmount(0)
            .withCategory('Other')
        .then
        .shouldFailWith('Amount must be positive')
        .run();
  });
}
