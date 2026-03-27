import '../expense_test_helper.dart';

void main() {
  expenseTest('should show no budgets message when none configured',
      (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    await system.navigateToBudget();
    system.verifyNoBudgets();
  });

  expenseTest('should display budget spending progress',
      (system, backend) async {
    backend.stubEmptyExpenses();
    backend.stubBudget(category: 'Food', limit: 200.00, spent: 120.00);
    await system.openApp();
    await system.navigateToBudget();
    system.verifyOnBudgetScreen();
    system.verifyBudgetInfo('Food');
  });

  expenseTest('should show over budget warning', (system, backend) async {
    backend.stubEmptyExpenses();
    backend.stubBudget(category: 'Entertainment', limit: 50.00, spent: 75.00);
    await system.openApp();
    await system.navigateToBudget();
    system.verifyOverBudget();
  });
}
