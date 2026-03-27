import '../expense_test_helper.dart';

void main() {
  expenseTest('should navigate to add expense screen', (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    await system.navigateToAddExpense();
    system.verifyOnAddScreen();
  });

  expenseTest('should add expense and show snack bar', (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    await system.navigateToAddExpense();
    await system.addExpense(
      description: 'Lunch',
      amount: '12.50',
      category: 'Food',
    );
    system.verifySnackBar('Expense added!');
  });

  expenseTest('should show validation errors for empty form',
      (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    await system.navigateToAddExpense();
    await system.submitEmptyForm();
    system.verifyValidationError('Description is required');
    system.verifyValidationError('Amount is required');
  });

  expenseTest('should show added expense in list after returning',
      (system, backend) async {
    backend.stubEmptyExpenses();
    await system.openApp();
    await system.navigateToAddExpense();
    await system.addExpense(
      description: 'Dinner',
      amount: '35.00',
      category: 'Food',
    );
    // After submit, we pop back to the list which refreshes
    system.verifyExpenseVisible('Dinner');
  });
}
