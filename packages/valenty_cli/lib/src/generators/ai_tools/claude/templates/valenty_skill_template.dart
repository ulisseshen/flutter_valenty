/// Template content for the Claude Code skill file.
///
/// This gets written to `.claude/skills/valenty-test/SKILL.md`
/// in the user's project when they run `valenty init` or `valenty generate skills`.
const valentySkillTemplate = r'''
---
name: valenty-test
description: >
  Unified test skill: generates acceptance tests (valentyTest), unit tests,
  fixtures, finders/matchers, and reviews test quality. One entry point for
  all testing needs. Uses AskUserQuestion to guide users step by step.
trigger: >
  Use when user says "write test", "generate test", "acceptance test",
  "unit test", "scaffold feature", "test for feature", "write scenario",
  "valentyTest", "component test", "review tests", "check test quality",
  "create fixture", "write unit tests", "valenty test", or provides a
  plain-English Given/When/Then scenario.
---

# Valenty Test — Unified Testing Skill

One entry point for all testing: acceptance tests, unit tests, fixtures,
finders, matchers, and quality review. Uses AskUserQuestion to guide users.

---

## Step 0: Ask the user what they need (MANDATORY)

Before writing ANY code, use **AskUserQuestion** to understand the request:

```
AskUserQuestion:
  question: "What would you like to do?"
  options:
    - "Write tests for a feature" (acceptance + failure scenarios)
    - "Write unit tests for logic" (pure functions, calculations)
    - "Review existing tests" (quality, fragility, naming)
    - "Generate tests for all features" (full onboarding)
```

Then based on the answer, follow the appropriate section below.

If the user already specified what they want (e.g., "write tests for login"),
skip this question and route directly.

---

## MANDATORY: Test Naming Rules (apply to ALL test types)

Every test name MUST describe **user-observable behavior**, not implementation.

### Good Names (Behavioral)
- "shows error message when network request fails"
- "displays total after adding expense"
- "rejects login with invalid email format"
- "preserves data after serialization round-trip"

### Bad Names (Implementation-Leaking) — REJECT THESE
- "should call repository.save()" (leaks method name)
- "should return UserDto" (leaks type name)
- "test verifyPin" (starts with 'test')
- "works correctly" (too vague)

### Naming Formula
```
<what happens> + [when <condition>]
```

Before generating test code, **list the test names first** and present them
to the user with AskUserQuestion:

```
AskUserQuestion:
  question: "Here are the test scenarios I'll generate. Confirm or adjust:"
  options:
    - "Looks good, generate them"
    - "I want to adjust some names"
    - "Add more scenarios"
```

---

## MANDATORY: Fixture System (apply to ALL routes — A, B, C, D)

**Every route MUST use this fixture system. No exceptions.**

Before creating ANY test data, follow this protocol:

### 1. SEARCH first — never duplicate

```
Glob: test/mocks/fixtures/**/*_fixtures.dart
Grep: "class.*Fixtures" in test/
```

If a fixture for the entity already exists → **reuse it**. Import it.
If it needs new variations → **add to the existing file** with `copyWith`.

### 2. CREATE only if not found

Place in `test/mocks/fixtures/<entity>_fixtures.dart` (or match project convention).

Rules:
- `abstract final class` — cannot be instantiated
- `valid` fixture with ALL fields populated
- `minimal` fixture with only required fields
- Deterministic: no `DateTime.now()`, no `Random()`
- Cross-reference related fixtures: `instructorId: InstructorFixtures.valid.id`
- Raw maps for Firestore/DTO testing

```dart
abstract final class ExpenseFixtures {
  static final valid = Expense(
    id: 'expense-001',
    description: 'Coffee',
    amount: 4.50,
    category: 'Food',
    date: DateTime(2025, 1, 15),
  );

  static final minimal = Expense(id: 'expense-min');

  static final list = [valid, minimal];

  static final validMap = <String, dynamic>{
    'id': 'expense-001',
    'description': 'Coffee',
    'amount': 4.50,
    'category': 'Food',
    'date': '2025-01-15T00:00:00.000',
  };

  /// Factory for custom variations
  static Expense withAmount(double amount) => valid.copyWith(amount: amount);
}
```

### 3. USE in all test types

**In valentyTest (Route A):**
```dart
setup: (backend) {
  backend.stubExpenses(ExpenseFixtures.list);  // NOT inline data
},
```

**In unit tests (Route B):**
```dart
test('calculates total from expenses', () {
  final total = calculateTotal(ExpenseFixtures.list);  // NOT inline data
  expect(total, equals(4.50));
});
```

**In parameterizedTest:**
```dart
parameterizedTest('formats currency', [
  [ExpenseFixtures.valid.amount, r'$4.50'],
  [0.0, r'$0.00'],
  [1000.0, r'$1,000.00'],
], (params) { ... });
```

### 4. REVIEW during Route C

When reviewing tests, flag any inline test data as a violation:
```
SMELL: test/feature_test.dart:15 — Inline Expense(...) instead of ExpenseFixtures.valid
FIX: Use ExpenseFixtures.valid or create a fixture variation
```

---

## MANDATORY: Finder & Matcher Rules (apply to valentyTest)

When creating UiDrivers, build **reusable finders** instead of repeating
`find.byKey` / `find.text` everywhere:

```dart
class ExpenseUiDriver extends UiDriver {
  // Reusable finders
  Finder expenseCard(String description) =>
      find.ancestor(of: find.text(description), matching: find.byType(ListTile));

  Finder submitButton() => find.byKey(const Key('submitButton'));

  // Reusable verification with clear error messages
  void verifyText(String text) {
    expect(find.text(text), findsOneWidget,
      reason: 'Expected to find "$text" on screen');
  }
}
```

For matchers, always implement `describeMismatch` for clear error messages.

---

## Route A: Write tests for a feature (acceptance tests)

### What to generate

For each feature, generate **all of these** — not just happy path:

1. **4 infrastructure files** (test helper, BackendStub, SystemDsl, UiDriver)
2. **Happy-path scenarios** — main user flows work
3. **Failure scenarios** — network errors, validation errors, permission denied
4. **Edge cases** — empty state, boundary values, special characters
5. **Parameterized tests** — input variations using `parameterizedTest`

### Architecture (valentyTest)

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

### Layer Responsibilities

| Layer | Responsibility | Example |
|-------|---------------|---------|
| `valentyTest()` | Creates driver, stubs, DSL; wraps testWidgets | `valentyTest('desc', setup: ..., body: ...)` |
| `BackendStubDsl` | Configure what fakes return | `backend.stubExpenses([...])` |
| `SystemDsl` | User actions + assertions in domain language | `system.openApp()`, `system.addExpense(...)` |
| `UiDriver` | Translates domain actions to widget interactions | `driver.tap(find.byKey('submitBtn'))` |
| `@visibleForTesting` | Production code hooks for dependency injection | `ExpenseService.fetchExpensesOverride = ...` |

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

### Complete Example

#### 1. valentyTest wrapper (test helper)

```dart
// test/valenty/expense_test_helper.dart
import 'package:flutter_test/flutter_test.dart';
import 'dsl/expense_backend_stub.dart';
import 'dsl/expense_system_dsl.dart';
import 'dsl/expense_ui_driver.dart';

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

#### 2. BackendStubDsl (fake configuration)

```dart
// test/valenty/dsl/expense_backend_stub.dart
import 'package:valenty_test/valenty_test.dart';
import 'package:my_app/models/expense.dart';
import 'package:my_app/services/expense_service.dart';

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

#### 3. SystemDsl (domain-language actions)

```dart
// test/valenty/dsl/expense_system_dsl.dart
import 'package:valenty_test/valenty_test.dart';
import 'expense_ui_driver.dart';

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
  void verifyExpenseVisible(String desc) => driver.verifyText(desc);
  void verifyEmptyState() => driver.verifyText('No expenses yet');
}
```

#### 4. UiDriver (widget interactions)

```dart
// test/valenty/dsl/expense_ui_driver.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valenty_test/valenty_test.dart';
import 'package:my_app/screens/expense_list_screen.dart';

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
  Future<void> enterDescription(String text) async {
    await tester.enterText(find.byKey(const Key('descriptionField')), text);
    await tester.pumpAndSettle();
  }
  Future<void> enterAmount(String text) async {
    await tester.enterText(find.byKey(const Key('amountField')), text);
    await tester.pumpAndSettle();
  }
  void verifyText(String text) => expect(find.text(text), findsOneWidget);
}
```

#### 5. Test scenario

```dart
// test/valenty/scenarios/add_expense_test.dart
import 'package:my_app/models/expense.dart';
import '../expense_test_helper.dart';

void main() {
  valentyTest(
    'should show total after adding expense',
    setup: (backend) {
      backend.stubExpenses([
        Expense(id: '1', description: 'Coffee', amount: 4.50,
                category: 'Food', date: DateTime(2025, 1, 1)),
      ]);
    },
    body: (system, backend) async {
      await system.openApp();
      system.verifyTotal('4.50');
    },
  );

  valentyTest(
    'should show empty state when no expenses exist',
    body: (system, backend) async {
      await system.openApp();
      system.verifyEmptyState();
    },
  );
}
```

### @visibleForTesting patterns for common Flutter dependencies

The rule: **1 line per dependency, zero behavior change.**

| Dependency | Production code change |
|------------|----------------------|
| `Dio()` | `@visibleForTesting static Dio Function() dioFactory = Dio.new` |
| `SharedPreferences.getInstance()` | `@visibleForTesting static Future<SharedPreferences> Function() prefsFactory` |
| `FirebaseFirestore.instance` | `@visibleForTesting static FirebaseFirestore Function() firestoreFactory` |
| `FirebaseAuth.instance` | `@visibleForTesting static FirebaseAuth Function() authFactory` |
| `DateTime.now()` | `@visibleForTesting static DateTime Function() clock = DateTime.now` |

**Example — making legacy code testable:**

```dart
// BEFORE (untestable)
class OrderService {
  Future<Order> place(Product p, int qty) async {
    final response = await Dio().post('/api/orders', data: {...});
    return Order.fromJson(response.data);
  }
}

// AFTER (1 line added — fully testable)
class OrderService {
  @visibleForTesting
  static Dio Function() dioFactory = Dio.new;  // <-- ONLY CHANGE

  Future<Order> place(Product p, int qty) async {
    final response = await dioFactory().post('/api/orders', data: {...});
    return Order.fromJson(response.data);
  }
}
```

### Scaffolding Checklist for valentyTest

When scaffolding a feature for valentyTest, follow this order:

1. **Read the screen/widget code** in `lib/` to find:
   - Entry point widget (e.g., `ExpenseListScreen`)
   - Interactive elements and their keys (buttons, text fields, dropdowns)
   - Data displayed on screen (lists, totals, labels)

2. **Read the service/repository code** to find:
   - Singleton dependencies to stub via `@visibleForTesting`
   - What data the services return (models)
   - Side effects (saving, deleting, API calls)

3. **Generate the file structure** under `test/valenty/`:
   - `<feature>_test_helper.dart` — the valentyTest wrapper
   - `dsl/<feature>_ui_driver.dart` — widget interactions
   - `dsl/<feature>_system_dsl.dart` — domain-language actions
   - `dsl/<feature>_backend_stub.dart` — fake configuration
   - `scenarios/` — test files

4. **Wire @visibleForTesting** overrides in production service classes (1 line each)

5. **Write scenario tests** that read like user stories

### Common Mistakes to Avoid with valentyTest

```dart
// MISTAKE 1: Not restoring overrides after test
// FIX: Always use try/finally in valentyTest wrapper (the template does this)

// MISTAKE 2: Forgetting pumpAndSettle after interactions
// FIX: Always call tester.pumpAndSettle() after tap/enter/navigate

// MISTAKE 3: Testing implementation details instead of user behavior
// BAD: driver.verifyWidgetState(myBloc.state)
// GOOD: system.verifyTotal('4.50')  // What the USER sees

// MISTAKE 4: Hardcoding test data in scenarios
// BAD: system.verifyTotal('4.50')  // Where does 4.50 come from?
// GOOD: setup: (backend) { backend.stubExpenses([...amount: 4.50...]); }
//       then: system.verifyTotal('4.50')  // Matches the stub

// MISTAKE 5: Not using Key widgets for findability
// FIX: Add const Key('submitButton') to widgets in production code
```

---

## Part B: Typed Builders (Logic-Only Tests) — Secondary

Use this approach ONLY when:
- Testing a pure Dart package (no Flutter)
- Testing complex domain logic that doesn't involve UI
- The user explicitly requests logic-only tests

For Flutter apps, always prefer valentyTest (Part A).

### Scaffold Feature Builders

When the user says something like "scaffold the Order feature for acceptance testing",
you must:

1. **Read the user's domain models** in `lib/` to understand the domain objects,
   their properties, and the use cases.
2. **Generate the complete builder tree** under `test/valenty/features/<feature>/`.

### Builder Architecture

The Valenty DSL has a strict class hierarchy. Each builder extends a base class
from `package:valenty_test/valenty_test.dart`:

```
FeatureScenario<TGiven>           -- Entry point: MyScenario('description')
  |
  +-- .given (getter)             -- Returns GivenBuilder subclass
  |
GivenBuilder                      -- Lists domain objects: .product(), .coupon()
  |
  +-- .product()                  -- Returns DomainObjectBuilder<NeedsWhen> subclass
  |
DomainObjectBuilder<NeedsWhen>    -- Fluent: .withName('x'), .withUnitPrice(20)
  |                                  Has: .when (transition), .and (more givens)
  |
  +-- .when (getter)              -- Returns WhenBuilder subclass
  |
WhenBuilder                       -- Lists use cases: .placeOrder(), .cancelOrder()
  |
  +-- .placeOrder()               -- Returns DomainObjectBuilder<NeedsThen> subclass
  |
DomainObjectBuilder<NeedsThen>    -- Fluent: .withQuantity(5)
  |                                  Has: .then (transition)
  |
  +-- .then (getter)              -- Returns ThenBuilder subclass
  |
ThenBuilder                       -- Simple assertions: .shouldSucceed(), .shouldFail()
  |                                  Assertion chains: .order() -> AssertionBuilder
  |
AssertionBuilder                  -- Fluent: .hasBasePrice(100), .hasQuantity(5)
  |                                  Has: .and (more assertions), .run()
  |
AndThenBuilder                    -- After .and in Then: .order() -> AssertionBuilder
```

### Phantom Types (Compile-Time Enforcement)

The DSL uses sealed phantom types to enforce Given -> When -> Then ordering:

```dart
sealed class ScenarioState {}
final class NeedsGiven extends ScenarioState {}   // initial state
final class NeedsWhen extends ScenarioState {}     // after .given
final class NeedsThen extends ScenarioState {}     // after .when
final class ReadyToRun extends ScenarioState {}    // after .then
```

`ScenarioBuilder<S>` carries the state type. Methods like `.addStep<T>()` transition
to a new state. The type system prevents calling `.when` before `.given`, etc.

### File Structure to Generate

```
test/valenty/features/<feature>/
+-- <feature>_scenario.dart              # FeatureScenario entry point
+-- builders/
|   +-- given/
|   |   +-- <feature>_given_builder.dart # GivenBuilder: lists domain objects
|   |   +-- <object>_given_builder.dart  # DomainObjectBuilder<NeedsWhen> per object
|   +-- when/
|   |   +-- <feature>_when_builder.dart  # WhenBuilder: lists use cases
|   |   +-- <usecase>_when_builder.dart  # DomainObjectBuilder<NeedsThen> per use case
|   +-- then/
|       +-- <feature>_then_builder.dart  # ThenBuilder: simple + chain assertions
|       +-- <feature>_assertion_builder.dart # AssertionBuilder for property checks
+-- scenarios/
    +-- (test files go here)
```

### Code Templates for Each Builder Type

#### 1. FeatureScenario (entry point)

```dart
import 'package:valenty_test/valenty_test.dart';

import 'builders/given/<feature>_given_builder.dart';

class <Feature>Scenario extends FeatureScenario<<Feature>GivenBuilder> {
  <Feature>Scenario(super.description);

  @override
  <Feature>GivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return <Feature>GivenBuilder(scenario);
  }
}
```

#### 2. GivenBuilder (lists domain objects)

```dart
import 'package:valenty_test/valenty_test.dart';

import '<object1>_given_builder.dart';
import '<object2>_given_builder.dart';

class <Feature>GivenBuilder extends GivenBuilder {
  <Feature>GivenBuilder(super.scenario);

  <Object1>GivenBuilder <object1>() => <Object1>GivenBuilder(scenario);
  <Object2>GivenBuilder <object2>() => <Object2>GivenBuilder(scenario);
}
```

#### 3. DomainObjectBuilder in Given phase

This is the most important builder. It configures a domain object with `.withX()`
methods and stores values to apply to the TestContext.

```dart
import 'package:valenty_test/valenty_test.dart';

import 'path/to/domain_model.dart';
import '../when/<feature>_when_builder.dart';
import '<feature>_given_builder.dart';

class <Object>GivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  <Object>GivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  // Default values for every property on the domain model
  String _name = 'Default';
  double _unitPrice = 0;

  // Fluent setters -- each returns `this` for chaining
  <Object>GivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  <Object>GivenBuilder withUnitPrice(double price) {
    _unitPrice = price;
    return this;
  }

  // CRITICAL: This method wires the builder to the actual domain model.
  // It creates the domain object and stores it in the TestContext.
  @override
  void applyToContext(TestContext ctx) {
    ctx.set('<object>', <DomainModel>(name: _name, unitPrice: _unitPrice));
  }

  // Transition to When phase
  <Feature>WhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return <Feature>WhenBuilder(next);
  }

  // Add another domain object to the Given phase
  <Feature>GivenBuilder get and {
    final finalized = finalizeStep();
    return <Feature>GivenBuilder(finalized);
  }
}
```

**Key rules for DomainObjectBuilder<NeedsWhen>:**
- Constructor takes `ScenarioBuilder<NeedsWhen>` and passes `StepPhase.given`
- `.withX()` methods store values and return `this`
- `applyToContext()` creates the actual domain object and puts it in TestContext
- `.when` getter calls `finalizeStep()`, then `addStep<NeedsThen>()`, returns WhenBuilder
- `.and` getter calls `finalizeStep()`, returns a new GivenBuilder (same scenario state)

#### 4. WhenBuilder (lists use cases)

```dart
import 'package:valenty_test/valenty_test.dart';

import '<usecase>_when_builder.dart';

class <Feature>WhenBuilder extends WhenBuilder {
  <Feature>WhenBuilder(super.scenario);

  <UseCase>WhenBuilder <useCase>() => <UseCase>WhenBuilder(scenario);
}
```

#### 5. DomainObjectBuilder in When phase (use case builder)

```dart
import 'package:valenty_test/valenty_test.dart';

import 'path/to/domain_models.dart';
import '../then/<feature>_then_builder.dart';

class <UseCase>WhenBuilder extends DomainObjectBuilder<NeedsThen> {
  <UseCase>WhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  <UseCase>WhenBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  // CRITICAL: This is where the actual use case logic runs.
  // Read preconditions from ctx, execute the use case, store the result.
  @override
  void applyToContext(TestContext ctx) {
    final product = ctx.get<Product>('product');
    // Execute use case logic
    final order = Order(
      quantity: _quantity,
      basePrice: product.unitPrice * _quantity,
      success: _quantity > 0,
    );
    ctx.set('order', order);
  }

  // Transition to Then phase
  <Feature>ThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return <Feature>ThenBuilder(next);
  }
}
```

**Key rules for DomainObjectBuilder<NeedsThen>:**
- Constructor takes `ScenarioBuilder<NeedsThen>` and passes `StepPhase.when`
- `applyToContext()` reads Given values from context, executes use case, stores result
- `.then` getter calls `finalizeStep()`, then `addStep<ReadyToRun>()`, returns ThenBuilder

#### 6. ThenBuilder (assertions)

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'path/to/domain_model.dart';
import '<feature>_assertion_builder.dart';

class <Feature>ThenBuilder extends ThenBuilder {
  <Feature>ThenBuilder(super.scenario);

  // Simple assertion: returns a terminal with .and and .run()
  <Feature>ThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final result = ctx.get<ResultModel>('result');
      expect(result.success, isTrue, reason: 'Expected success');
    });
    return <Feature>ThenTerminal(next);
  }

  <Feature>ThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final result = ctx.get<ResultModel>('result');
      expect(result.success, isFalse, reason: 'Expected failure');
    });
    return <Feature>ThenTerminal(next);
  }

  // Fluent assertion chain
  <Feature>AssertionBuilder <resultObject>() =>
      <Feature>AssertionBuilder(scenario);
}

// Terminal state after shouldSucceed()/shouldFail()
class <Feature>ThenTerminal {
  <Feature>ThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  <Feature>AndThenBuilder get and => <Feature>AndThenBuilder(scenario);
  void run() => ScenarioRunner.run(scenario);
}

// AndThenBuilder for additional assertions after .and
class <Feature>AndThenBuilder extends AndThenBuilder {
  <Feature>AndThenBuilder(super.scenario);

  <Feature>AssertionBuilder <resultObject>() =>
      <Feature>AssertionBuilder(scenario);
}
```

#### 7. AssertionBuilder (property assertions)

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'path/to/domain_model.dart';
import '<feature>_then_builder.dart';

class <Feature>AssertionBuilder extends AssertionBuilder {
  <Feature>AssertionBuilder(super.scenario);

  <Feature>AssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.basePrice, equals(expected),
          reason: 'Expected base price to be $expected');
    });
    return this;
  }

  <Feature>AssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.quantity, equals(expected),
          reason: 'Expected quantity to be $expected');
    });
    return this;
  }

  // Chain more assertions
  <Feature>AndThenBuilder get and => <Feature>AndThenBuilder(currentScenario);

  // Execute the test
  void run() => ScenarioRunner.run(currentScenario);
}
```

### TestContext API (Complete Reference)

`TestContext` is a typed key-value store shared across all Given/When/Then steps.
A fresh context is created for each scenario -- no state leaks between tests.

```dart
ctx.set<T>(String key, T value)   // Store a value. Overwrites if key exists.
ctx.get<T>(String key)            // Retrieve a value. Throws StateError if missing.
ctx.has(String key)               // Check if a key exists. Returns bool.
ctx.clear()                       // Clear all values (rarely needed).
```

**CRITICAL: Always specify the type parameter on `ctx.get<T>()`:**
```dart
// CORRECT:
final product = ctx.get<Product>('product');
final discount = ctx.get<double>('couponDiscount');

// WRONG — will fail with type cast error:
final product = ctx.get('product');  // Returns dynamic, not Product
```

**CRITICAL: Use `ctx.has()` for optional preconditions:**

```dart
// CORRECT — handles both "with coupon" and "without coupon" scenarios:
final discount = ctx.has('couponDiscount')
    ? ctx.get<double>('couponDiscount')
    : 0.0;

// WRONG — crashes with StateError when no coupon was given:
final discount = ctx.get<double>('couponDiscount');
```

### Async applyToContext() Pattern

When a builder step needs async work (API calls, database reads, file I/O),
override `applyToContext()` as `Future<void>` instead of `void`. The `ScenarioRunner`
automatically detects `Future` return values and awaits them -- no extra wiring.

```dart
@override
Future<void> applyToContext(TestContext ctx) async {
  final response = await apiClient.fetchOrder(id: _orderId);
  ctx.set('order', response);
}
```

Sync and async builders mix freely in the same scenario chain.

### Common LLM Mistakes to Avoid (Typed Builders)

```dart
// MISTAKE 1: Missing ctx.has() check for optional values
final discount = ctx.get<double>('couponDiscount');  // CRASHES if no coupon!
// FIX: Always guard optional values:
final discount = ctx.has('couponDiscount') ? ctx.get<double>('couponDiscount') : 0.0;

// MISTAKE 2: Forgetting type parameter on ctx.get()
final product = ctx.get('product');  // Returns dynamic, not Product!
// FIX: Always specify the type:
final product = ctx.get<Product>('product');

// MISTAKE 3: Inventing methods that don't exist on builders
.then.order().hasTotal(100)  // hasTotal() doesn't exist!
// FIX: ALWAYS read the actual builder files first. Only use methods that exist.

// MISTAKE 4: Using wrong context key name
ctx.set('prod', product);     // In Given
ctx.get<Product>('product');  // In When — CRASH! Keys must match exactly.

// MISTAKE 5: Forgetting .run() at the end
OrderScenario('test').given.product()...then.shouldSucceed();  // Test never runs!
// FIX: Always end with .run()

// MISTAKE 6: Using parentheses on .given, .when, .then
.given().product()  // WRONG — .given is a getter, not a method
.given.product()    // CORRECT
```

### Typed Builder Test Example

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

### Parameterized Tests

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

- Each inner list is one test case; a separate `test()` is created per case
- Cast `params[i]` to the correct type
- Comment the first case to label each position
- Use string interpolation in the scenario description for traceability

---

## Rules

### DO:
- **Default to valentyTest (Part A) for Flutter apps**
- **Always read the domain models / screen code in `lib/`** before scaffolding
- **Always read existing builders/DSL** before writing test code
- Use `.given`, `.when`, `.then` as getters (no parentheses) in typed builders
- Use `.and` to chain multiple givens or multiple assertions
- Use `.run()` at the end of typed builder chains
- Keep scenario descriptions behavior-focused: "should calculate base price"
- One scenario per business rule
- Import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Import `package:valenty_test/valenty_test.dart` in every builder/DSL file

### DON'T:
- **Never use typed builders for Flutter apps** unless the user explicitly asks
- **Never invent builder methods** that don't exist in the code
- Never use strings for step descriptions (that's Gherkin, not this DSL)
- Never skip reading the builders/DSL -- you must know what methods are available
- Never write `.given()` with parentheses -- it's a getter: `.given`
- Never forget `.run()` at the end of a scenario chain
- Never create builders without extending the correct base class

### When Builders Don't Exist Yet:

If the scenario references a domain concept with no builder, tell the user you
need to scaffold it first. Offer to create the builder files, then write the tests.

---

## Compile-Time Safety (Typed Builders)

The following would NOT compile -- the compiler catches errors before runtime:

```dart
// Cannot skip given:
OrderScenario('bad').when.placeOrder()  // ERROR: no 'when' on FeatureScenario

// Cannot skip when:
OrderScenario('bad').given.product().then  // ERROR: no 'then' on ProductGivenBuilder

// Cannot invent methods:
OrderScenario('bad').given.spaceship()  // ERROR: no 'spaceship()' on GivenBuilder

// Cannot use wrong assertion:
OrderScenario('bad')...then.order().hasWarpDrive(true)  // ERROR: no 'hasWarpDrive'
```

Invalid tests do not compile. That is the key advantage over textual Gherkin.

## Route B: Write unit tests for logic

Use when testing **pure functions, calculations, transformations, business rules**
that don't need UI.

### What to test
- Pure calculations (tax, discounts, totals, formatting)
- Data transformations (model mapping, serialization, parsing)
- Business rules (eligibility, validation, state machines)
- Edge cases in algorithms (sorting, filtering, pagination)

### Always use parameterizedTest for variations

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

void main() {
  parameterizedTest(
    'calculates discount correctly',
    [
      [100.0, 0.10, 90.0],   // 10% off
      [100.0, 0.25, 75.0],   // 25% off
      [50.0, 0.50, 25.0],    // 50% off
      [200.0, 0.0, 200.0],   // no discount
      [200.0, 1.0, 0.0],     // 100% off
    ],
    (List<dynamic> params) {
      final price = params[0] as double;
      final rate = params[1] as double;
      final expected = params[2] as double;
      expect(applyDiscount(price, rate), equals(expected));
    },
  );
}
```

### Manual fakes only — NO mocktail/mockito

All test doubles are hand-written:

```dart
class FakeExpenseRepository implements ExpenseRepository {
  List<Expense>? expensesToReturn;
  Exception? exceptionToThrow;
  int fetchCallCount = 0;

  @override
  Future<List<Expense>> fetchAll() async {
    fetchCallCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return expensesToReturn!;
  }
}
```

### Always create fixtures — never inline test data

See MANDATORY: Fixture Rules above.

---

## Route C: Review existing tests

Run quality checks on existing tests. Do ALL of these:

### 1. Behavioral naming check
Scan all `_test.dart` files. Flag any test name that:
- Mentions method names ("should call save()")
- Mentions class names ("should return UserDto")
- Is vague ("works correctly", "test verifyPin")
- Starts with "test" or "should call"

### 2. Fragile test hunt
Look for these patterns in test files:

**CRITICAL (will break CI):**
- `DateTime.now()` in tests
- `Future.delayed()` / `sleep()`
- `Random()` without seed
- Shared mutable state between tests
- Missing `tearDown` for setup state
- Network calls without mocks

**WARNING (likely to break):**
- `pump()` without `pumpAndSettle()`
- Magic numbers in assertions
- `setUpAll` with mutable state
- Assertions on widget tree structure

**SMELL (poor practice):**
- Test file > 500 lines
- Inline test data (should be fixtures)
- `skip: true` annotations
- Commented-out test code
- No `setUp` / `tearDown`

### 3. Coupling check
For each test, ask: would this break if we:
- Changed an internal method signature?
- Moved a method between classes?
- Merged or split internal classes?

If YES → test is coupled to implementation, not behavior.

### 4. Report format

```
## Test Quality Report

**Scanned**: X files | Y tests
**Verdict**: CLEAN / PROBATION / CONDEMNED

### Naming Issues (X found)
- `file_test.dart` — "should call repository.save()" → "saves expense to storage"

### Fragility (X critical, Y warning)
- `file_test.dart:42` — DateTime.now() → Use fixture date

### Coupling (X tests)
- `file_test.dart` — mocks internal validator → test via public API

### Fixes Applied
[list of automated fixes made]
```

---

## Route D: Generate tests for all features (full onboarding)

See the `valenty-onboarding` skill for the full onboarding flow.

---

## Final Step: Verify and offer to go deeper

### 1. Run tests

```bash
flutter test test/valenty/
```

Fix failures immediately. Never leave broken tests.

### 2. Ask about gaps and edge cases (MANDATORY)

After all tests pass, use **AskUserQuestion**:

```
AskUserQuestion:
  question: "Tests are passing. Want to go deeper?"
  multiSelect: true
  options:
    - "Add failure scenarios" (network errors, validation, permission denied)
    - "Add edge cases" (empty inputs, boundary values, special characters)
    - "Add parameterized variations" (multiple inputs for same logic)
    - "Review test quality" (naming, fragility, coupling check)
```

If the user selects any option, generate the additional tests and run again.
Repeat this cycle until the user is satisfied.

This ensures progressive coverage — start with essentials, deepen on demand.
''';
