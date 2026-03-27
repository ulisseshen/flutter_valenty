import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/expense.dart';

class ExpenseService {
  ExpenseService._();

  static final ExpenseService _instance = ExpenseService._();
  static ExpenseService get instance => _instance;

  final List<Expense> _expenses = [];

  // ---------------------------------------------------------------------------
  // @visibleForTesting overrides
  // ---------------------------------------------------------------------------

  @visibleForTesting
  static Future<List<Expense>> Function()? fetchExpensesOverride;

  @visibleForTesting
  static Future<void> Function(Expense)? addExpenseOverride;

  @visibleForTesting
  static Future<List<Budget>> Function()? getBudgetsOverride;

  @visibleForTesting
  static void resetForTesting() {
    fetchExpensesOverride = null;
    addExpenseOverride = null;
    getBudgetsOverride = null;
    _instance._expenses.clear();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<List<Expense>> fetchExpenses() async {
    if (fetchExpensesOverride != null) {
      return fetchExpensesOverride!();
    }
    return List.unmodifiable(_expenses);
  }

  Future<void> addExpense(Expense expense) async {
    if (addExpenseOverride != null) {
      return addExpenseOverride!(expense);
    }
    _expenses.add(expense);
  }

  Future<List<Budget>> getBudgets() async {
    if (getBudgetsOverride != null) {
      return getBudgetsOverride!();
    }
    return [];
  }
}
