import 'package:test/test.dart' show addTearDown;
import 'package:valenty_test/valenty_test.dart';

import 'builders/given/expense_given_builder.dart';
import 'setup/expense_test_environment.dart';

/// Entry point for Expense feature acceptance tests.
///
/// Automatically creates an [ExpenseTestEnvironment] and wires it into
/// the test context as the first Given step. The environment is
/// applied (singleton overrides activated) when the test runs,
/// and restored via addTearDown after the test body completes.
///
/// Usage:
/// ```dart
/// ExpenseScenario('should add expense with correct amount')
///     .given
///     .auth()
///         .asUser('user-1', 'user@test.com')
///     .and
///     .apiExpenses()
///         .withPostEnabled()
///     .when
///     .addExpense()
///         .withDescription('Coffee')
///         .withAmount(4.50)
///         .withCategory('Food')
///     .then
///     .shouldSucceed()
///     .run();
/// ```
class ExpenseScenario extends FeatureScenario<ExpenseGivenBuilder> {
  ExpenseScenario(super.description);

  @override
  ExpenseGivenBuilder createGivenBuilder(
    ScenarioBuilder<NeedsWhen> scenario,
  ) {
    final withEnv = scenario.appendStep(
      StepRecord(
        phase: StepPhase.given,
        action: (ctx) {
          final env = ExpenseTestEnvironment()..apply();
          ctx.set('_testEnv', env);
          addTearDown(() => env.restore());
        },
      ),
    );
    return ExpenseGivenBuilder(withEnv);
  }
}
