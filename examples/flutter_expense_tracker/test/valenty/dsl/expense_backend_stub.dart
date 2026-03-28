import 'package:valenty_test/valenty_test.dart';

import 'package:flutter_expense_tracker/models/budget.dart';
import 'package:flutter_expense_tracker/models/expense.dart';
import 'package:flutter_expense_tracker/services/expense_service.dart';

class ExpenseBackendStub extends BackendStubDsl {
  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  final List<Expense> addedExpenses = [];

  void stubExpenses(List<Expense> expenses) {
    _expenses = expenses;
  }

  void stubEmptyExpenses() {
    _expenses = [];
  }

  void stubBudget({
    required String category,
    required double limit,
    required double spent,
  }) {
    _budgets.add(Budget(category: category, limit: limit, spent: spent));
  }

  void stubBudgets(List<Budget> budgets) {
    _budgets = budgets;
  }

  @override
  Future<void> apply() async {
    ExpenseService.fetchExpensesOverride = () async {
      return List.unmodifiable(_expenses);
    };
    ExpenseService.addExpenseOverride = (expense) async {
      addedExpenses.add(expense);
      _expenses = [..._expenses, expense];
    };
    ExpenseService.getBudgetsOverride = () async {
      return List.unmodifiable(_budgets);
    };
  }

  @override
  Future<void> restore() async {
    ExpenseService.resetForTesting();
  }
}
