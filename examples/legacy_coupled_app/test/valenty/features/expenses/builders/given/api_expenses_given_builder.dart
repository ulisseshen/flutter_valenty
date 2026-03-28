import 'package:valenty_test/valenty_test.dart';

import '../when/expense_when_builder.dart';
import 'expense_given_builder.dart';

/// Builder for configuring API expense responses in the Given phase.
///
/// Available methods:
/// - `.withExpense(...)` — add an expense to the API GET response
/// - `.withPostEnabled()` — enable POST /api/expenses
/// - `.withApiError(statusCode)` — configure the API to fail
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class ApiExpensesGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiExpensesGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Map<String, dynamic>> _expenses = [];
  bool _postEnabled = false;
  int? _errorCode;

  /// Add a single expense to the API GET response.
  ApiExpensesGivenBuilder withExpense({
    required String id,
    required String description,
    required double amount,
    required String category,
    String userId = 'test-user',
    DateTime? date,
  }) {
    _expenses.add({
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'userId': userId,
      'date': (date ?? DateTime(2025, 6, 15, 10, 30)).toIso8601String(),
    });
    return this;
  }

  /// Enable POST /api/expenses so addExpense() works.
  ApiExpensesGivenBuilder withPostEnabled() {
    _postEnabled = true;
    return this;
  }

  /// Configure the expenses API to fail with the given HTTP status code.
  ApiExpensesGivenBuilder withApiError(int statusCode) {
    _errorCode = statusCode;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('apiExpensesResponse')
        ? ctx.get<List<Map<String, dynamic>>>('apiExpensesResponse')
        : <Map<String, dynamic>>[];

    existing.addAll(_expenses);
    ctx.set('apiExpensesResponse', existing);

    if (_postEnabled) {
      ctx.set('apiPostEnabled', true);
    }

    if (_errorCode != null) {
      ctx.set('apiHasError', true);
      ctx.set('apiErrorCode', _errorCode!);
    }
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
