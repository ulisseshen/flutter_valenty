import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'expense_then_builder.dart';

/// Fluent assertion builder for spending-by-category map.
///
/// Available assertions:
/// - `.hasCategory(category, amount)` — assert spending for a category
/// - `.hasCategoryCount(int)` — assert number of categories
/// - `.isEmpty()` — assert no spending data
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class SpendingAssertionBuilder extends AssertionBuilder {
  SpendingAssertionBuilder(super.scenario);

  /// Assert spending for a category equals the expected amount.
  SpendingAssertionBuilder hasCategory(String category, double amount) {
    addAssertionStep((ctx) {
      final spending = ctx.get<Map<String, double>>('spendingMap');
      expect(
        spending.containsKey(category),
        isTrue,
        reason: 'Expected spending to contain category "$category"',
      );
      expect(
        spending[category],
        closeTo(amount, 0.01),
        reason: 'Expected spending for "$category" to be $amount',
      );
    });
    return this;
  }

  /// Assert the number of categories in spending.
  SpendingAssertionBuilder hasCategoryCount(int expected) {
    addAssertionStep((ctx) {
      final spending = ctx.get<Map<String, double>>('spendingMap');
      expect(
        spending.length,
        equals(expected),
        reason:
            'Expected $expected categories, got ${spending.length}',
      );
    });
    return this;
  }

  /// Assert spending map is empty.
  SpendingAssertionBuilder isEmpty() {
    addAssertionStep((ctx) {
      final spending = ctx.get<Map<String, double>>('spendingMap');
      expect(
        spending,
        hasLength(0),
        reason: 'Expected spending map to be empty',
      );
    });
    return this;
  }

  /// Add more assertions.
  ExpenseAndThenBuilder get and => ExpenseAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
