import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/expense_when_builder.dart';
import 'expense_given_builder.dart';

/// Builder for configuring budgets in the Given phase.
///
/// Available methods:
/// - `.withBudget(category, limit, spent)` — set a budget for a category
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class BudgetGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  BudgetGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Map<String, dynamic>> _budgets = [];

  /// Set a budget for a category.
  BudgetGivenBuilder withBudget({
    required String category,
    required double limit,
    required double spent,
  }) {
    _budgets.add({
      'category': category,
      'limit': limit,
      'spent': spent,
    });
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('budgetsData')
        ? ctx.get<List<Map<String, dynamic>>>('budgetsData')
        : <Map<String, dynamic>>[];

    existing.addAll(_budgets);
    ctx.set('budgetsData', existing);
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
