import 'package:meta/meta.dart';

import '../models/budget.dart';
import '../models/expense.dart';

/// LocalStorage singleton with mixed concerns.
///
/// BAD: Acts as both a cache and a persistence layer.
/// BAD: Knows about domain entities (Expense, Budget).
class LocalStorage {
  static final instance = LocalStorage._();
  LocalStorage._();

  final Map<String, dynamic> _store = {};

  Future<void> addExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    _store['expenses'] = expenses.map((e) => e.toJson()).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final data = _store['expenses'] as List?;
    if (data == null) return [];
    return data
        .map((j) => Expense.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    _store['expenses'] = expenses.map((e) => e.toJson()).toList();
  }

  Future<Budget?> getBudget(String category) async {
    final data = _store['budget_$category'] as Map<String, dynamic>?;
    if (data == null) return null;
    return Budget.fromJson(data);
  }

  Future<void> saveBudget(Budget budget) async {
    _store['budget_${budget.category}'] = budget.toJson();
  }

  @visibleForTesting
  void clearForTesting() => _store.clear();
}
