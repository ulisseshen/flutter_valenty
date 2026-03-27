import '../expense_test_helper.dart';

void main() {
  valentyTest(
    'should show no budgets message when none configured',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToBudget();
      system.verifyNoBudgets();
    },
  );

  valentyTest(
    'should display budget spending progress',
    setup: (backend) {
      backend.stubBudget(category: 'Food', limit: 200.00, spent: 120.00);
    },
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToBudget();
      system.verifyOnBudgetScreen();
      system.verifyBudgetInfo('Food');
    },
  );

  valentyTest(
    'should show over budget warning',
    setup: (backend) {
      backend.stubBudget(
        category: 'Entertainment',
        limit: 50.00,
        spent: 75.00,
      );
    },
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToBudget();
      system.verifyOverBudget();
    },
  );
}
