import 'package:legacy_coupled_app_example/services/local_storage.dart';
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'expense_then_builder.dart';

/// Fluent assertion builder for stored expense properties.
///
/// Checks the FIRST expense in LocalStorage (most recently added).
///
/// Available assertions:
/// - `.hasDescription(String)` — assert the description
/// - `.hasAmount(double)` — assert the amount
/// - `.hasCategory(String)` — assert the category
/// - `.hasUserId(String)` — assert the userId
/// - `.hasDate(DateTime)` — assert the date
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ExpenseAssertionBuilder extends AssertionBuilder {
  ExpenseAssertionBuilder(super.scenario);

  /// Assert the stored expense has the expected description.
  ExpenseAssertionBuilder hasDescription(String expected) {
    addAssertionStep((ctx) async {
      final expenses = await LocalStorage.instance.getExpenses();
      expect(expenses, isNotEmpty, reason: 'No expenses stored');
      expect(
        expenses.last.description,
        equals(expected),
        reason: 'Expected description "$expected"',
      );
    });
    return this;
  }

  /// Assert the stored expense has the expected amount.
  ExpenseAssertionBuilder hasAmount(double expected) {
    addAssertionStep((ctx) async {
      final expenses = await LocalStorage.instance.getExpenses();
      expect(expenses, isNotEmpty, reason: 'No expenses stored');
      expect(
        expenses.last.amount,
        equals(expected),
        reason: 'Expected amount $expected',
      );
    });
    return this;
  }

  /// Assert the stored expense has the expected category.
  ExpenseAssertionBuilder hasCategory(String expected) {
    addAssertionStep((ctx) async {
      final expenses = await LocalStorage.instance.getExpenses();
      expect(expenses, isNotEmpty, reason: 'No expenses stored');
      expect(
        expenses.last.category,
        equals(expected),
        reason: 'Expected category "$expected"',
      );
    });
    return this;
  }

  /// Assert the stored expense has the expected userId.
  ExpenseAssertionBuilder hasUserId(String expected) {
    addAssertionStep((ctx) async {
      final expenses = await LocalStorage.instance.getExpenses();
      expect(expenses, isNotEmpty, reason: 'No expenses stored');
      expect(
        expenses.last.userId,
        equals(expected),
        reason: 'Expected userId "$expected"',
      );
    });
    return this;
  }

  /// Assert the stored expense has the expected date.
  ExpenseAssertionBuilder hasDate(DateTime expected) {
    addAssertionStep((ctx) async {
      final expenses = await LocalStorage.instance.getExpenses();
      expect(expenses, isNotEmpty, reason: 'No expenses stored');
      expect(
        expenses.last.date,
        equals(expected),
        reason: 'Expected date $expected',
      );
    });
    return this;
  }

  /// Add more assertions.
  ExpenseAndThenBuilder get and => ExpenseAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
