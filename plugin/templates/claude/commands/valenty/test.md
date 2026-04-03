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

### UiDriver: use reusable finders AND matchers

```dart
class ExpenseUiDriver extends UiDriver {
  // Reusable finders
  Finder expenseCard(String desc) =>
      find.ancestor(of: find.text(desc), matching: find.byType(ListTile));

  void verifyText(String text) {
    expect(find.text(text), findsOneWidget, reason: 'Expected "$text" on screen');
  }
}
```

Create custom matchers when assertions need clear error messages:

```dart
/// Matcher: verifies a widget contains specific text
Matcher hasChildWithText(String expected) => _HasChildWithText(expected);

class _HasChildWithText extends Matcher {
  final String expected;
  const _HasChildWithText(this.expected);

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Finder || item.evaluate().isEmpty) return false;
    return find.descendant(of: item, matching: find.text(expected))
        .evaluate().isNotEmpty;
  }

  @override
  Description describe(Description d) => d.add('has child with text "$expected"');

  @override
  Description describeMismatch(Object? item, Description d, Map m, bool v) =>
      d.add('does not contain text "$expected"');
}
```

**Rules for matchers:**
- Always implement `describeMismatch` — "does not match" is useless
- Create only when used 3+ times
- Place in `test/helpers/matchers.dart` (or project convention)

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

## Final: Run, review, and offer to go deeper

### Run tests

```bash
dart run valenty_test:failed_tests valenty
```

This returns ONLY failures — saves context when there are thousands of tests.

### Auto-review what was generated

After tests pass, spawn **2 agents in parallel** to review the generated code:

```
Agent(
  description="Review generated test names",
  prompt="Review test names in test/valenty/scenarios/. REJECT any that mention
  method names, class names, or are vague. For each bad name, provide the fix.
  Output a table: File | Current | Suggested."
)

Agent(
  description="Review generated fixtures/stubs",
  prompt="Review test/valenty/dsl/ and test/mocks/fixtures/. Check:
  1. No inline test data in scenario files
  2. Fixtures are deterministic (no DateTime.now)
  3. BackendStub has matching restore() for every apply()
  4. Finders in UiDriver are reusable (not duplicated)
  Output issues found with fixes."
)
```

Apply any fixes from the review agents.

### Ask about going deeper

AskUserQuestion (multiSelect):
```
question: "Tests passing and reviewed. Want to go deeper?"
options:
  - Add failure scenarios (network errors, validation, permissions)
  - Add edge cases (empty inputs, boundary values, special chars)
  - Add parameterized variations
  - Run full quality review (/valenty:review)
```

Repeat until user is done.

</process>
