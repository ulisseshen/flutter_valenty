# Valenty Init

Initialize Valenty in the current Flutter project. Add valenty_test dependency, scan the codebase, and generate the first test scenarios.

## Step 1: Verify Flutter project

Read `pubspec.yaml`. If it doesn't exist, tell the user to run this from a Flutter project root.
Check if `valenty_test` is already in dev_dependencies.

## Step 2: Add valenty_test

If not present, add `valenty_test: ^0.2.3` to dev_dependencies in pubspec.yaml.
Then run `flutter pub get`.

If there's a dependency conflict, show the error and suggest checking `flutter pub outdated`.

## Step 3: Scan the project

Read the codebase to understand:
- **Services** in `lib/` — classes that call APIs, databases, Firebase, etc.
- **Screens/Pages** in `lib/` — what the user sees
- **Models** in `lib/` — data classes, entities
- **State management** — Riverpod, Bloc, Provider, etc.

## Step 4: Ask which feature to test first

Present a list of the most testable features found and ask the user which one to start with. Include a "Let me describe a different one" option.

## Step 5: Generate the 4 infrastructure files

For the chosen feature, create:

1. **Test Helper** (`test/valenty/<feature>_test_helper.dart`) — wraps `testWidgets` with setup/teardown lifecycle, creates BackendStub, UiDriver, SystemDsl per test.

2. **BackendStubDsl** (`test/valenty/dsl/<feature>_backend_stub.dart`) — extends `BackendStubDsl` from valenty_test, has `stubX()` methods, `apply()` overrides `@visibleForTesting` factories, `restore()` resets to originals.

3. **SystemDsl** (`test/valenty/dsl/<feature>_system_dsl.dart`) — extends `SystemDsl` from valenty_test, domain-language methods like `openApp()`, `addExpense()`, `verifyTotal()`, delegates to UiDriver.

4. **UiDriver** (`test/valenty/dsl/<feature>_ui_driver.dart`) — extends `UiDriver` from valenty_test, wraps WidgetTester with reusable finders.

**IMPORTANT:** If service classes don't have `@visibleForTesting` override points, add them:

```dart
class ExpenseService {
  @visibleForTesting
  static Future<List<Expense>> Function() fetchOverride = _fetchReal;
  static Future<List<Expense>> fetch() => fetchOverride();
  @visibleForTesting
  static void resetForTesting() { fetchOverride = _fetchReal; }
}
```

## Step 6: Create fixtures

Search `test/mocks/fixtures/` for existing fixtures. For each model used in tests, create a fixture class if not found:

```dart
abstract final class ExpenseFixtures {
  static final valid = Expense(id: 'expense-001', description: 'Coffee', amount: 4.50);
  static final minimal = Expense(id: 'expense-min');
  static final list = [valid, minimal];
}
```

## Step 7: Generate test scenarios

Create `test/valenty/scenarios/<feature>_test.dart` with:
1. **Happy path** — main user flow works
2. **Empty state** — what user sees with no data
3. **Data from backend** — stub data appears correctly

**Test naming rule:** Every name must describe user-observable behavior.
Good: "shows empty state when no expenses exist"
Bad: "should call repository.fetchAll()"

Present the test names to the user before generating code.

## Step 8: Run tests

```bash
flutter test test/valenty/
```

Fix any failures.

## Step 9: Ask about going deeper

Ask the user if they want to:
- Add failure scenarios (network errors, validation)
- Add edge cases (empty inputs, boundary values)
- Add parameterized test variations
- Review test quality

Generate additional tests for selected options. Repeat until user is done.
