import '../expense_test_helper.dart';

void main() {
  valentyTest('should navigate from list to add expense and back',
      (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    system.verifyEmptyState();

    await system.navigateToAddExpense();
    system.verifyOnAddScreen();

    await system.goBack();
    system.verifyEmptyState();
  });

  valentyTest('should navigate from list to budget screen and back',
      (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    system.verifyEmptyState();

    await system.navigateToBudget();
    system.verifyOnBudgetScreen();

    await system.goBack();
    system.verifyEmptyState();
  });
}
