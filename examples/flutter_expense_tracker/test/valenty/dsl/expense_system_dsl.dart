import 'package:valenty_test/valenty_test.dart';

import 'expense_ui_driver.dart';

class ExpenseSystemDsl extends SystemDsl {
  ExpenseSystemDsl(this.driver);

  final ExpenseUiDriver driver;

  Future<void> openApp() async {
    await driver.pumpApp();
  }

  Future<void> navigateToAddExpense() async {
    await driver.tapFab();
  }

  Future<void> navigateToBudget() async {
    await driver.tapBudgetButton();
  }

  Future<void> addExpense({
    required String description,
    required String amount,
    String category = 'Food',
  }) async {
    await driver.enterDescription(description);
    await driver.enterAmount(amount);
    if (category != 'Food') {
      await driver.selectCategory(category);
    }
    await driver.tapSubmit();
  }

  Future<void> submitEmptyForm() async {
    await driver.tapSubmit();
  }

  void verifyExpenseVisible(String description) {
    driver.verifyText(description);
  }

  void verifyTotal(String amount) {
    driver.verifyText('Total: \$$amount');
  }

  void verifyExpenseCount(int count) {
    driver.verifyListItemCount(count);
  }

  void verifySnackBar(String message) {
    driver.verifyText(message);
  }

  void verifyOnAddScreen() {
    driver.verifyTextExists('Add Expense');
  }

  void verifyOnBudgetScreen() {
    driver.verifyText('Budget Summary');
  }

  void verifyOverBudget() {
    driver.verifyText('Over budget!');
  }

  void verifyEmptyState() {
    driver.verifyText('No expenses yet');
  }

  void verifyNoBudgets() {
    driver.verifyText('No budgets configured');
  }

  void verifyValidationError(String error) {
    driver.verifyValidationError(error);
  }

  void verifyBudgetInfo(String text) {
    driver.verifyTextExists(text);
  }

  Future<void> goBack() async {
    await driver.tapBack();
  }
}
