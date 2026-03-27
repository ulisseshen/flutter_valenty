import '../expense_test_helper.dart';

void main() {
  valentyTest(
    'should navigate to add expense screen',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToAddExpense();
      system.verifyOnAddScreen();
    },
  );

  valentyTest(
    'should add expense and show snack bar',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToAddExpense();
      await system.addExpense(
        description: 'Lunch',
        amount: '12.50',
        category: 'Food',
      );
      system.verifySnackBar('Expense added!');
    },
  );

  valentyTest(
    'should show validation errors for empty form',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToAddExpense();
      await system.submitEmptyForm();
      system.verifyValidationError('Description is required');
      system.verifyValidationError('Amount is required');
    },
  );

  valentyTest(
    'should show added expense in list after returning',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToAddExpense();
      await system.addExpense(
        description: 'Dinner',
        amount: '35.00',
        category: 'Food',
      );
      system.verifyExpenseVisible('Dinner');
    },
  );
}
