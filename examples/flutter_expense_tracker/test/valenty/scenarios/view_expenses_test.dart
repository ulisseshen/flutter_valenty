import 'package:flutter_expense_tracker/models/expense.dart';

import '../expense_test_helper.dart';

void main() {
  valentyTest(
    'should show empty state when no expenses exist',
    body: (system, backend) async {
      await system.openApp();
      system.verifyEmptyState();
    },
  );

  valentyTest(
    'should display expenses with descriptions and amounts',
    setup: (backend) {
      backend.stubExpenses([
        Expense(
          id: '1',
          description: 'Coffee',
          amount: 4.50,
          category: 'Food',
          date: DateTime(2025, 1, 1),
        ),
        Expense(
          id: '2',
          description: 'Bus',
          amount: 2.00,
          category: 'Transport',
          date: DateTime(2025, 1, 1),
        ),
      ]);
    },
    body: (system, backend) async {
      await system.openApp();
      system.verifyExpenseVisible('Coffee');
      system.verifyExpenseVisible('Bus');
    },
  );

  valentyTest(
    'should show correct total',
    setup: (backend) {
      backend.stubExpenses([
        Expense(
          id: '1',
          description: 'A',
          amount: 10.00,
          category: 'Food',
          date: DateTime(2025, 1, 1),
        ),
        Expense(
          id: '2',
          description: 'B',
          amount: 25.50,
          category: 'Food',
          date: DateTime(2025, 1, 1),
        ),
      ]);
    },
    body: (system, backend) async {
      await system.openApp();
      system.verifyTotal('35.50');
    },
  );
}
