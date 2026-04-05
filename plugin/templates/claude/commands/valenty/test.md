---
name: valenty:test
description: Write tests — component tests for user scenarios (valentyTest) or unit tests for edge cases (typedParameterizedTest)
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
Write tests using Valenty's two test types:

- **Component tests** (valentyTest) — validate what users SEE and DO.
  Written in domain language. Test the full app with faked externals.
- **Unit tests** (typedParameterizedTest) — cover business rules and edge cases.
  Written with typed cases. Test validations, calculations, formatting, and boundaries.

Component tests catch bugs users hit. Unit tests catch rules and edge cases developers define.
</objective>

<process>

## Step 0: Route

If `$ARGUMENTS` is provided, infer the test type from context:
- Mentions a feature, screen, flow, user action → **component test**
- Mentions a function, calculation, formatting, validation logic → **unit test**

Otherwise, use **AskUserQuestion**:

```
question: "What would you like to test?"
options:
  - A user scenario (component test — what users see and do)
  - Business rules and edge cases (unit test — rules and boundaries developers define)
  - Both for a feature (component + unit tests)
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

## Route A: Component test — what users see and do

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

## Route B: Unit test — business rules from the developer's perspective

For business rules: calculations, validations, formatting, eligibility, state transitions, parsing.

Always use **typed test cases** — no raw `params[0] as double`:

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

class DiscountCase extends TestCase {
  final double price;
  final double rate;
  final double expected;
  const DiscountCase({
    required this.price,
    required this.rate,
    required this.expected,
  });
  @override
  String get label => '${rate * 100}% off \$$price = \$$expected';
}

typedParameterizedTest('calculates discount', [
  DiscountCase(price: 100, rate: 0.10, expected: 90),
  DiscountCase(price: 100, rate: 0.25, expected: 75),
  DiscountCase(price: 200, rate: 0.0, expected: 200),
  DiscountCase(price: 200, rate: 1.0, expected: 0),
], (c) {
  expect(applyDiscount(c.price, c.rate), equals(c.expected));
});
```

**Always create a TestCase class** for each domain concept being tested.
The `label` getter makes test output readable:
```
calculates discount [case 1: 10.0% off $100.0 = $90.0]  ✓
calculates discount [case 4: 100.0% off $200.0 = $0.0]  ✓
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
