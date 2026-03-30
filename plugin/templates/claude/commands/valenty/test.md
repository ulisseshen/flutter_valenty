---
name: valenty:test
description: Write tests — routes to acceptance test (valentyTest), unit test, or parameterized based on user input
argument-hint: "[feature or description]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

<objective>
Write tests for the current Flutter project using Valenty patterns.
Routes to the right test type based on user input.
</objective>

<process>

## Step 0: Route

If `$ARGUMENTS` is provided, infer the test type from context.
Otherwise, use **AskUserQuestion**:

```
question: "What would you like to test?"
options:
  - A feature flow (acceptance test with valentyTest)
  - A specific function or logic (unit test)
  - Generate tests for all features
```

## MANDATORY: Fixture System

Before creating ANY test data:
1. Search `test/mocks/fixtures/` for existing fixtures
2. If found → reuse. Import it.
3. If not found → create fixture class (abstract final, deterministic, no DateTime.now())
4. NEVER inline test data in tests

## MANDATORY: Test Naming

Every test name describes **user-observable behavior**, not implementation.

Good: "displays total after adding expense"
Bad: "should call repository.save()"

**Before generating code**, list test names and present to user with AskUserQuestion:
```
question: "Here are the test scenarios. Confirm or adjust:"
options:
  - Looks good, generate them
  - I want to adjust some names
  - Add more scenarios
```

---

## Route A: Feature flow (acceptance test)

### What to generate

For the feature, check if infrastructure exists:
- `test/valenty/<feature>_test_helper.dart` — if missing, create it
- `test/valenty/dsl/<feature>_backend_stub.dart` — if missing, create it
- `test/valenty/dsl/<feature>_system_dsl.dart` — if missing, create it
- `test/valenty/dsl/<feature>_ui_driver.dart` — if missing, create it

Then generate scenarios in `test/valenty/scenarios/<feature>_test.dart`:

```dart
valentyTest(
  'displays total after adding expense',
  setup: (backend) {
    backend.stubExpenses(ExpenseFixtures.list);  // Use fixtures!
  },
  body: (system, backend) async {
    await system.openApp();
    system.verifyTotal('4.50');
  },
);
```

### UiDriver: use reusable finders

```dart
class ExpenseUiDriver extends UiDriver {
  Finder expenseCard(String desc) =>
      find.ancestor(of: find.text(desc), matching: find.byType(ListTile));

  void verifyText(String text) {
    expect(find.text(text), findsOneWidget, reason: 'Expected "$text" on screen');
  }
}
```

---

## Route B: Unit test

For pure logic (calculations, transformations, business rules).

Use `parameterizedTest` for variations:

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

parameterizedTest('calculates discount', [
  [100.0, 0.10, 90.0],
  [100.0, 0.25, 75.0],
  [200.0, 0.0, 200.0],
], (params) {
  final price = params[0] as double;
  final rate = params[1] as double;
  final expected = params[2] as double;
  expect(applyDiscount(price, rate), equals(expected));
});
```

Manual fakes only — no mocktail/mockito:

```dart
class FakeExpenseRepo implements ExpenseRepository {
  List<Expense>? expensesToReturn;
  Exception? exceptionToThrow;

  @override
  Future<List<Expense>> fetchAll() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return expensesToReturn!;
  }
}
```

---

## Final: Run and offer to go deeper

```bash
flutter test test/valenty/
```

Then AskUserQuestion (multiSelect):
```
question: "Tests passing. Want to go deeper?"
options:
  - Add failure scenarios
  - Add edge cases
  - Add parameterized variations
  - Review test quality
```

Repeat until user is done.

</process>
