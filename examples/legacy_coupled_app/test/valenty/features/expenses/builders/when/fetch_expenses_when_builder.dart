import 'package:legacy_coupled_app_example/models/expense.dart';
import 'package:legacy_coupled_app_example/services/auth_manager.dart';
import 'package:legacy_coupled_app_example/services/expense_screen_controller.dart';
import 'package:legacy_coupled_app_example/services/local_storage.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../setup/expense_test_environment.dart';
import '../then/expense_then_builder.dart';

/// Builder for the "fetch expenses" action.
///
/// No additional configuration needed — just `.then` to transition.
class FetchExpensesWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  FetchExpensesWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  @override
  void applyToContext(TestContext ctx) {
    final env = ctx.get<ExpenseTestEnvironment>('_testEnv');

    // Set up auth from context
    final userId =
        ctx.has('authUserId') ? ctx.get<String>('authUserId') : 'test-user';
    final email = ctx.has('authEmail')
        ? ctx.get<String>('authEmail')
        : 'test@example.com';
    AuthManager.instance.setForTesting(userId: userId, email: email);

    // Configure the fake HTTP client from context
    final hasError =
        ctx.has('apiHasError') ? ctx.get<bool>('apiHasError') : false;

    if (hasError) {
      final errorCode = ctx.get<int>('apiErrorCode');
      env.fakeHttp.configureGetError('/api/expenses', errorCode);
    } else {
      final apiExpenses = ctx.has('apiExpensesResponse')
          ? ctx.get<List<Map<String, dynamic>>>('apiExpensesResponse')
          : <Map<String, dynamic>>[];
      env.fakeHttp.configureGet('/api/expenses', apiExpenses);
    }

    // Pre-populate cache if needed
    final cachedExpenses = ctx.has('cachedExpensesData')
        ? ctx.get<List<Map<String, dynamic>>>('cachedExpensesData')
        : <Map<String, dynamic>>[];

    if (cachedExpenses.isNotEmpty) {
      final expenses =
          cachedExpenses.map((j) => Expense.fromJson(j)).toList();
      LocalStorage.instance.saveExpenses(expenses);
    }

    ctx.set('_expenseAction', () async {
      try {
        final controller = ExpenseScreenController();
        final expenses = await controller.getExpenses();
        return _FetchResult.success(expenses);
      } catch (e) {
        return _FetchResult.failure(e.toString());
      }
    });
  }

  /// Transition to Then phase.
  ExpenseThenBuilder get then {
    final finalized = finalizeStep();

    final withExecution = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final action =
              ctx.get<Future<_FetchResult> Function()>('_expenseAction');
          final result = await action();
          if (result.isSuccess) {
            ctx.set('expenseList', result.expenses!);
            ctx.set('operationFailed', false);
          } else {
            ctx.set('operationFailed', true);
            ctx.set('operationError', result.error!);
          }
        },
      ),
    );

    final next = withExecution.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return ExpenseThenBuilder(next);
  }
}

class _FetchResult {
  _FetchResult.success(this.expenses)
      : isSuccess = true,
        error = null;

  _FetchResult.failure(this.error)
      : isSuccess = false,
        expenses = null;

  final bool isSuccess;
  final List<Expense>? expenses;
  final String? error;
}
