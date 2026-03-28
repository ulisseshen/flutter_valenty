/// Template content for the AGENTS.md file.
///
/// This gets written to `AGENTS.md` in the user's project root
/// when they run `valenty init` or `valenty generate skills`.
const codexAgentTemplate = r'''# Valenty: UI-First Component Testing

## Overview

This project uses **Valenty** (`package:valenty_test`) for component testing.
The primary approach is **valentyTest** (UI-first with stubbed backends).
The secondary approach is **typed fluent DSL builders** for logic-only tests.

**Always default to valentyTest for Flutter apps.**

## IMPORTANT: Always prefer valentyTest (UI-first)

When asked to write tests, DEFAULT to valentyTest with full app setup.

If the user explicitly asks for logic-only tests (no UI), WARN them:

"Testing without the UI misses widget rendering errors, navigation bugs, state
management issues, form validation, and layout problems — the bugs that reach
production most often. Recommended: use valentyTest with full app setup."

---

## Part A: valentyTest (Component Tests with UI) — PRIMARY

### Architecture

```
valentyTest('description', setup: ..., body: ...)
    |
    +-- BackendStubDsl       <-- configure fakes (setup parameter)
    |   +-- @visibleForTesting factory overrides
    |
    +-- SystemDsl            <-- domain-language user actions
    |   +-- UiDriver         <-- wraps WidgetTester
    |
    +-- testWidgets          <-- Flutter test framework
```

### What AI generates per feature

```
test/valenty/
├── expense_test_helper.dart          # valentyTest() wrapper
├── dsl/
│   ├── expense_system_dsl.dart       # Domain actions: openApp(), addExpense()
│   ├── expense_backend_stub.dart     # Stub config: stubExpenses(), stubBudget()
│   └── expense_ui_driver.dart        # Widget interactions: tap, enter, verify
└── scenarios/
    └── add_expense_test.dart         # Test scenarios using valentyTest
```

### valentyTest wrapper pattern

```dart
void valentyTest(
  String description, {
  void Function(ExpenseBackendStub backend)? setup,
  required Future<void> Function(
    ExpenseSystemDsl system,
    ExpenseBackendStub backend,
  ) body,
}) {
  testWidgets(description, (tester) async {
    final backend = ExpenseBackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = ExpenseUiDriver(tester);
      final system = ExpenseSystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
```

### BackendStubDsl pattern

```dart
class ExpenseBackendStub extends BackendStubDsl {
  final List<Expense> _expenses = [];

  void stubExpenses(List<Expense> expenses) => _expenses.addAll(expenses);

  @override
  Future<void> apply() async {
    ExpenseService.fetchExpensesOverride = () async => List.of(_expenses);
  }

  @override
  Future<void> restore() async {
    ExpenseService.resetForTesting();
  }
}
```

### SystemDsl pattern

```dart
class ExpenseSystemDsl extends SystemDsl {
  ExpenseSystemDsl(this.driver);
  final ExpenseUiDriver driver;

  Future<void> openApp() async => driver.pumpApp();
  Future<void> addExpense({required String desc, required String amount}) async {
    await driver.enterDescription(desc);
    await driver.enterAmount(amount);
    await driver.tapSubmit();
  }
  void verifyTotal(String total) => driver.verifyText('Total: \$$total');
}
```

### UiDriver pattern

```dart
class ExpenseUiDriver extends UiDriver {
  ExpenseUiDriver(this.tester);
  final WidgetTester tester;

  Future<void> pumpApp() async {
    await tester.pumpWidget(const MaterialApp(home: ExpenseListScreen()));
    await tester.pumpAndSettle();
  }
  Future<void> tapSubmit() async {
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();
  }
  void verifyText(String text) => expect(find.text(text), findsOneWidget);
}
```

### Test scenario example

```dart
valentyTest(
  'should show total after adding expense',
  setup: (backend) {
    backend.stubExpenses([
      Expense(id: '1', description: 'Coffee', amount: 4.50, ...),
    ]);
  },
  body: (system, backend) async {
    await system.openApp();
    system.verifyTotal('4.50');
  },
);
```

### @visibleForTesting patterns

| Dependency | Production code change |
|------------|----------------------|
| `Dio()` | `@visibleForTesting static Dio Function() dioFactory = Dio.new` |
| `SharedPreferences.getInstance()` | `@visibleForTesting static Future<SharedPreferences> Function() prefsFactory` |
| `FirebaseFirestore.instance` | `@visibleForTesting static FirebaseFirestore Function() firestoreFactory` |
| `FirebaseAuth.instance` | `@visibleForTesting static FirebaseAuth Function() authFactory` |
| `DateTime.now()` | `@visibleForTesting static DateTime Function() clock = DateTime.now` |

The rule: **1 line per dependency, zero behavior change.**

---

## Part B: Typed Builders (Logic-Only Tests) — Secondary

Use this approach ONLY when:
- Testing a pure Dart package (no Flutter)
- Testing complex domain logic that doesn't involve UI
- The user explicitly requests logic-only tests

For Flutter apps, always prefer valentyTest (Part A).

### Class Hierarchy

```
FeatureScenario<TGiven>           -- Entry point: MyScenario('description')
GivenBuilder                      -- Lists domain objects: .product(), .coupon()
DomainObjectBuilder<NeedsWhen>    -- .withX() fluent config, .when/.and transitions
WhenBuilder                       -- Lists use cases: .placeOrder()
DomainObjectBuilder<NeedsThen>    -- .withX() fluent config, .then transition
ThenBuilder                       -- .shouldSucceed(), .order() assertions
AssertionBuilder                  -- .hasBasePrice(), .hasQuantity(), .run()
```

### Phantom Types

```dart
sealed class ScenarioState {}
final class NeedsGiven extends ScenarioState {}   // initial
final class NeedsWhen extends ScenarioState {}     // after .given
final class NeedsThen extends ScenarioState {}     // after .when
final class ReadyToRun extends ScenarioState {}    // after .then
```

### File Structure

```
test/valenty/features/<feature>/
+-- <feature>_scenario.dart
+-- builders/
|   +-- given/  (GivenBuilder + DomainObjectBuilder<NeedsWhen>)
|   +-- when/   (WhenBuilder + DomainObjectBuilder<NeedsThen>)
|   +-- then/   (ThenBuilder + AssertionBuilder)
+-- scenarios/  (test files)
```

### Key Pattern: applyToContext()

- **Given phase**: Create domain objects and store via `ctx.set('key', object)`
- **When phase**: Read Given values via `ctx.get<T>('key')`, execute use case, store result
- **Then phase**: Read results via `ctx.get<T>('key')`, assert with `expect()`

### TestContext API

```dart
ctx.set<T>(String key, T value)   // Store a value
ctx.get<T>(String key)            // Retrieve typed value (throws StateError if missing)
ctx.has(String key)               // Check if key exists (returns bool)
ctx.clear()                       // Clear all values
```

**Always specify type on get:** `ctx.get<Product>('product')` not `ctx.get('product')`

**Guard optional values with ctx.has():**
```dart
final discount = ctx.has('couponDiscount')
    ? ctx.get<double>('couponDiscount')
    : 0.0;
```

### Async applyToContext()

For async work, return `Future<void>` instead of `void`. The runner awaits
futures automatically. Sync and async builders mix freely.

### Example

```dart
OrderScenario('should calculate base price as unit price times quantity')
    .given
    .product()
    .withUnitPrice(20.00)
    .when
    .placeOrder()
    .withQuantity(5)
    .then
    .shouldSucceed()
    .and
    .order()
    .hasBasePrice(100.00)
    .run();
```

### Common Mistakes

- `ctx.get('key')` without type param — returns dynamic, causes cast errors
- `ctx.get<T>('key')` on optional values without `ctx.has()` — crashes with StateError
- Inventing `.hasX()` methods — always read actual builders first
- Mismatched context keys between Given and When phases
- Missing `.run()` at end — test never executes
- `.given()` with parens — it's a getter: `.given`

## Parameterized Tests

Use `parameterizedTest()` from `package:valenty_test` to run one scenario against
multiple data sets without copy-paste:

```dart
parameterizedTest(
  'should calculate correct base price',
  [
    [10.0, 2, 20.0],   // unitPrice, quantity, expectedBasePrice
    [25.0, 4, 100.0],
    [5.0, 10, 50.0],
  ],
  (values) {
    final unitPrice = values[0] as double;
    final quantity = values[1] as int;
    final expected = values[2] as double;

    OrderScenario('base price = $unitPrice x $quantity')
        .given.product().withUnitPrice(unitPrice)
        .when.placeOrder().withQuantity(quantity)
        .then.order().hasBasePrice(expected)
        .run();
  },
);
```

## Rules

- Default to valentyTest for Flutter apps, typed builders for pure Dart only
- Never invent builder methods that do not exist in the code
- Never use `.given()`, `.when()`, `.then()` with parentheses
- Always import `package:valenty_test/valenty_test.dart` in builder files
- Always import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Invalid tests will not compile -- the compiler enforces correct structure

## Onboarding

When setting up Valenty (`valenty init`), scan the project first:
1. Detect AI tools (`.claude/`, `.cursor/`, `.opencode/`, `AGENTS.md`)
2. Find domain models in `lib/`
3. Detect project type — Flutter vs pure Dart
4. Present findings and ask the user which AI clients and features to set up
5. Execute setup commands based on user choices

Always confirm with the user before proceeding.
''';
