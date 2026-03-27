import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/expense_when_builder.dart';
import 'expense_given_builder.dart';

/// Builder for pre-populating cached expenses in the Given phase.
///
/// Available methods:
/// - `.withExpense(...)` — add an expense to the local cache
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class CachedExpensesGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CachedExpensesGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Map<String, dynamic>> _cachedExpenses = [];

  /// Add an expense to the local cache.
  CachedExpensesGivenBuilder withExpense({
    required String id,
    required String description,
    required double amount,
    required String category,
    String userId = 'test-user',
    DateTime? date,
  }) {
    _cachedExpenses.add({
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'userId': userId,
      'date': (date ?? DateTime(2025, 6, 15, 10, 30)).toIso8601String(),
    });
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('cachedExpensesData')
        ? ctx.get<List<Map<String, dynamic>>>('cachedExpensesData')
        : <Map<String, dynamic>>[];

    existing.addAll(_cachedExpenses);
    ctx.set('cachedExpensesData', existing);
  }

  /// Transition to When phase.
  ExpenseWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return ExpenseWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  ExpenseGivenBuilder get and {
    final finalized = finalizeStep();
    return ExpenseGivenBuilder(finalized);
  }
}
