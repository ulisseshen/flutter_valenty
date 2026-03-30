---
name: valenty-test
description: Write Flutter tests using Valenty patterns — acceptance tests with valentyTest, unit tests with parameterizedTest, manual fakes, and deterministic fixtures
---

# Valenty Test Skill

You are an expert at writing Flutter tests using the Valenty methodology based on the Modern Test Pyramid.

## Core Principles

1. **Behavior, not implementation** — test names describe what the user sees, never internal method calls
2. **Deterministic fixtures** — no DateTime.now(), no Random(), no inline test data
3. **Manual fakes only** — no mocktail, no mockito
4. **Three-layer DSL** — BackendStubDsl (arrange), SystemDsl (act), UiDriver (interact)

## Test Types

### Acceptance Test (valentyTest)

For feature flows. Uses the full DSL stack:

```dart
valentyTest(
  'displays total after adding expense',
  setup: (backend) {
    backend.stubExpenses(ExpenseFixtures.list);
  },
  body: (system, backend) async {
    await system.openApp();
    system.verifyTotal('4.50');
  },
);
```

Infrastructure files needed:
- `test/valenty/<feature>_test_helper.dart`
- `test/valenty/dsl/<feature>_backend_stub.dart`
- `test/valenty/dsl/<feature>_system_dsl.dart`
- `test/valenty/dsl/<feature>_ui_driver.dart`

### Unit Test (parameterizedTest)

For pure logic — calculations, transformations, business rules:

```dart
parameterizedTest('calculates discount', [
  [100.0, 0.10, 90.0],
  [100.0, 0.25, 75.0],
], (params) {
  final price = params[0] as double;
  final rate = params[1] as double;
  final expected = params[2] as double;
  expect(applyDiscount(price, rate), equals(expected));
});
```

## Fixture Pattern

```dart
abstract final class ExpenseFixtures {
  static final valid = Expense(id: 'expense-001', description: 'Coffee', amount: 4.50);
  static final minimal = Expense(id: 'expense-min');
  static final list = [valid, minimal];
}
```

Always search `test/mocks/fixtures/` for existing fixtures before creating new ones.

## Manual Fake Pattern

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

## Workflow

1. Identify the test type (acceptance or unit)
2. Search for existing fixtures and infrastructure
3. Create missing infrastructure files
4. List test names and confirm with the user before generating
5. Generate tests
6. Run `flutter test test/valenty/` and fix failures
7. Ask if the user wants to go deeper (failure scenarios, edge cases, parameterized variations)
