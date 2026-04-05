---
description: Setup Flutter project for Valenty testing — adds dependency, scans features, generates first tests
---

// turbo

## 1. Verify Flutter project

Read `pubspec.yaml`. If it doesn't exist, tell the user to run this from a Flutter project root.
Check if `valenty_test` is already in dev_dependencies.

## 2. Add valenty_test

If not present, add `valenty_test: ^0.2.3` to dev_dependencies in pubspec.yaml.
Then run `flutter pub get`.

If there's a dependency conflict, show the error and suggest checking
`flutter pub outdated` for which package needs updating.

## 3. Scan the project

Read the codebase to understand:
- **Services** in `lib/` — classes that call APIs, databases, Firebase, etc.
- **Screens/Pages** in `lib/` — what the user sees
- **Models** in `lib/` — data classes, entities
- **State management** — Riverpod, Bloc, Provider, etc.

## 4. Ask which feature to test first

Present the user with options based on the scan:

"I scanned your project. Which feature should we test first?"
- (most testable feature found — recommended)
- (second feature)
- (third feature)
- Or describe a different one

Wait for the user's response before continuing.

## 5. Generate the 4 infrastructure files

For the chosen feature, create:

1. **Test Helper** (`test/valenty/<feature>_test_helper.dart`)
   - Wraps `testWidgets` with setup/teardown lifecycle
   - Creates BackendStub, UiDriver, SystemDsl per test

2. **BackendStubDsl** (`test/valenty/dsl/<feature>_backend_stub.dart`)
   - Extends `BackendStubDsl` from valenty_test
   - Has `stubX()` methods for each service dependency
   - `apply()` overrides @visibleForTesting factories
   - `restore()` resets to originals

3. **SystemDsl** (`test/valenty/dsl/<feature>_system_dsl.dart`)
   - Extends `SystemDsl` from valenty_test
   - Domain-language methods: `openApp()`, `addExpense()`, `verifyTotal()`
   - Delegates to UiDriver

4. **UiDriver** (`test/valenty/dsl/<feature>_ui_driver.dart`)
   - Extends `UiDriver` from valenty_test
   - Wraps WidgetTester with reusable finders
   - `pumpApp()`, `tapX()`, `enterX()`, `verifyText()`

**IMPORTANT:** If the service classes don't have `@visibleForTesting` override points,
add them. Example:

```dart
class ExpenseService {
  @visibleForTesting
  static Future<List<Expense>> Function() fetchOverride = _fetchReal;
  static Future<List<Expense>> fetch() => fetchOverride();
  @visibleForTesting
  static void resetForTesting() { fetchOverride = _fetchReal; }
}
```

## 6. Create fixtures

Search `test/mocks/fixtures/` (or project convention) for existing fixtures.
For each model used in tests, create a fixture class if not found:

```dart
abstract final class ExpenseFixtures {
  static final valid = Expense(id: 'expense-001', description: 'Coffee', amount: 4.50, ...);
  static final minimal = Expense(id: 'expense-min');
  static final list = [valid, minimal];
  static final validMap = <String, dynamic>{'id': 'expense-001', ...};
}
```

## 7. Generate test scenarios

Create `test/valenty/scenarios/<feature>_test.dart` with:

1. **Happy path** — main user flow works
2. **Empty state** — what user sees with no data
3. **Data from backend** — stub data appears correctly

**Test naming rule:** Every name must describe user-observable behavior.
Good: "shows empty state when no expenses exist"
Bad: "should call repository.fetchAll()"

Present the test names to the user and wait for confirmation before generating code.

## 8. Run tests

```bash
flutter test test/valenty/
```

Fix any failures.

## 9. Ask about going deeper

Ask the user if they want to continue:

"Tests are passing. Want to go deeper?"
- Add failure scenarios (network errors, validation)
- Add edge cases (empty inputs, boundary values)
- Add parameterized test variations
- Review test quality

Generate additional tests for selected options. Repeat until user is done.
