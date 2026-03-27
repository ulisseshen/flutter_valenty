import 'package:meta/meta.dart';

import '../models/expense.dart';
import 'auth_manager.dart';
import 'http_client.dart';
import 'local_storage.dart';
import 'notification_service.dart';

/// Simulates a Flutter widget/screen with business logic embedded directly.
/// In a real app, this would be a StatefulWidget with all logic in setState().
///
/// BAD: Business logic, API calls, storage, and navigation all in one place.
/// This is the "God widget" — the worst anti-pattern in legacy Flutter apps.
class ExpenseScreenController {
  @visibleForTesting
  static HttpClient Function() httpClientFactory = () => RealHttpClient();

  @visibleForTesting
  static DateTime Function() clockFactory = () => DateTime.now();

  // BAD: Business logic, API calls, storage, and navigation all in one place
  Future<void> addExpense(
    String description,
    double amount,
    String category,
  ) async {
    // Validates directly
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    if (description.isEmpty) throw ArgumentError('Description required');

    // Calls API directly (hardcoded)
    final client = httpClientFactory();
    final response = await client.post('/api/expenses', data: {
      'description': description,
      'amount': amount,
      'category': category,
      'userId': AuthManager.instance.currentUserId!, // static chain!
      'date': clockFactory().toIso8601String(), // factory clock!
    });

    // Saves to local storage directly
    final storage = LocalStorage.instance;
    await storage.addExpense(Expense.fromJson(response as Map<String, dynamic>));

    // Updates budget tracking directly
    final budget = await storage.getBudget(category);
    if (budget != null) {
      final remaining = budget.limit - budget.spent - amount;
      if (remaining < 0) {
        NotificationService.showWarning('Over budget in $category!');
      }
    }
  }

  Future<List<Expense>> getExpenses() async {
    // Tries API first, falls back to cache
    try {
      final client = httpClientFactory();
      final userId = AuthManager.instance.currentUserId!;
      final data = await client.get('/api/expenses?userId=$userId');
      final expenses =
          (data as List).map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList();
      await LocalStorage.instance.saveExpenses(expenses);
      return expenses;
    } catch (e) {
      return await LocalStorage.instance.getExpenses();
    }
  }

  Future<Map<String, double>> getSpendingByCategory() async {
    final expenses = await getExpenses();
    final grouped = <String, double>{};
    for (final e in expenses) {
      grouped[e.category] = (grouped[e.category] ?? 0) + e.amount;
    }
    return grouped;
  }
}
