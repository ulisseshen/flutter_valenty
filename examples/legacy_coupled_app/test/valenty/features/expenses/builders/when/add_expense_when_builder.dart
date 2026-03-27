import 'package:legacy_coupled_app_example/models/budget.dart';
import 'package:legacy_coupled_app_example/models/expense.dart';
import 'package:legacy_coupled_app_example/services/auth_manager.dart';
import 'package:legacy_coupled_app_example/services/expense_screen_controller.dart';
import 'package:legacy_coupled_app_example/services/local_storage.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../setup/expense_test_environment.dart';
import '../then/expense_then_builder.dart';

/// Builder for the "add expense" action.
///
/// Available methods:
/// - `.withDescription(String)` — set the expense description
/// - `.withAmount(double)` — set the expense amount
/// - `.withCategory(String)` — set the expense category
/// - `.then` — transition to Then phase
class AddExpenseWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  AddExpenseWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _description = '';
  double _amount = 0;
  String _category = '';

  /// Set the expense description.
  AddExpenseWhenBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  /// Set the expense amount.
  AddExpenseWhenBuilder withAmount(double amount) {
    _amount = amount;
    return this;
  }

  /// Set the expense category.
  AddExpenseWhenBuilder withCategory(String category) {
    _category = category;
    return this;
  }

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

    // Override clock if specified
    if (ctx.has('fixedClock')) {
      final fixedDate = ctx.get<DateTime>('fixedClock');
      ExpenseScreenController.clockFactory = () => fixedDate;
    }

    // Configure POST endpoint on fake HTTP
    final postEnabled =
        ctx.has('apiPostEnabled') ? ctx.get<bool>('apiPostEnabled') : false;

    if (postEnabled) {
      int nextId = 100;
      env.fakeHttp.configurePost('/api/expenses', (data) {
        final id = '${nextId++}';
        return {
          'id': id,
          'description': data?['description'] as String,
          'amount': data?['amount'] as num,
          'category': data?['category'] as String,
          'userId': data?['userId'] as String,
          'date': data?['date'] as String,
        };
      });
    }

    // Pre-populate budgets if needed
    final budgets = ctx.has('budgetsData')
        ? ctx.get<List<Map<String, dynamic>>>('budgetsData')
        : <Map<String, dynamic>>[];

    for (final b in budgets) {
      LocalStorage.instance.saveBudget(Budget.fromJson(b));
    }

    // Pre-populate cached expenses if needed
    final cachedExpenses = ctx.has('cachedExpensesData')
        ? ctx.get<List<Map<String, dynamic>>>('cachedExpensesData')
        : <Map<String, dynamic>>[];

    if (cachedExpenses.isNotEmpty) {
      final expenses =
          cachedExpenses.map((j) => Expense.fromJson(j)).toList();
      LocalStorage.instance.saveExpenses(expenses);
    }

    final description = _description;
    final amount = _amount;
    final category = _category;

    ctx.set('_expenseAction', () async {
      try {
        final controller = ExpenseScreenController();
        await controller.addExpense(description, amount, category);
        return _ExpenseActionResult.success();
      } catch (e) {
        return _ExpenseActionResult.failure(e.toString());
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
              ctx.get<Future<_ExpenseActionResult> Function()>(
                  '_expenseAction');
          final result = await action();
          ctx.set('expenseActionResult', result);
          ctx.set('operationFailed', !result.isSuccess);
          if (!result.isSuccess) {
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

class _ExpenseActionResult {
  _ExpenseActionResult.success()
      : isSuccess = true,
        error = null;

  _ExpenseActionResult.failure(this.error)
      : isSuccess = false;

  final bool isSuccess;
  final String? error;
}
