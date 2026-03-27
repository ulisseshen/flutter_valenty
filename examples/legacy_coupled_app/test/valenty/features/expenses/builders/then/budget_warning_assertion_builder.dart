import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../setup/expense_test_environment.dart';
import 'expense_then_builder.dart';

/// Fluent assertion builder for budget warning notifications.
///
/// Available assertions:
/// - `.wasSent()` — assert at least one warning was sent
/// - `.wasNotSent()` — assert no warnings were sent
/// - `.containsMessage(String)` — assert a warning contains text
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class BudgetWarningAssertionBuilder extends AssertionBuilder {
  BudgetWarningAssertionBuilder(super.scenario);

  /// Assert at least one budget warning was sent.
  BudgetWarningAssertionBuilder wasSent() {
    addAssertionStep((ctx) {
      final env = ctx.get<ExpenseTestEnvironment>('_testEnv');
      expect(
        env.capturedWarnings,
        isNotEmpty,
        reason: 'Expected at least one budget warning to be sent',
      );
    });
    return this;
  }

  /// Assert no budget warnings were sent.
  BudgetWarningAssertionBuilder wasNotSent() {
    addAssertionStep((ctx) {
      final env = ctx.get<ExpenseTestEnvironment>('_testEnv');
      expect(
        env.capturedWarnings,
        isEmpty,
        reason: 'Expected no budget warnings to be sent',
      );
    });
    return this;
  }

  /// Assert a budget warning contains the given text.
  BudgetWarningAssertionBuilder containsMessage(String substring) {
    addAssertionStep((ctx) {
      final env = ctx.get<ExpenseTestEnvironment>('_testEnv');
      expect(
        env.capturedWarnings.any((msg) => msg.contains(substring)),
        isTrue,
        reason:
            'Expected a warning containing "$substring", '
            'got: ${env.capturedWarnings}',
      );
    });
    return this;
  }

  /// Add more assertions.
  ExpenseAndThenBuilder get and => ExpenseAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
