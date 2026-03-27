/// Template content for the Cursor MDC rule file.
///
/// This gets written to `.cursor/rules/valenty.mdc`
/// in the user's project when they run `valenty init` or `valenty generate skills`.
const cursorRuleTemplate = r'''---
description: >
  Scaffold typed fluent DSL builders for features and generate compile-time safe
  acceptance tests from QA scenarios using Valenty's typed fluent DSL.
globs:
  - test/valenty/**/*.dart
  - test/**/*_test.dart
alwaysApply: false
---

# Valenty: Typed Fluent DSL for Acceptance Testing

You scaffold **typed fluent DSL builders** and write **compile-time safe acceptance
tests** using the Valenty DSL (`package:valenty_dsl`).

## Architecture

The DSL uses phantom types to enforce Given -> When -> Then ordering at compile time.

### Class Hierarchy

```
FeatureScenario<TGiven>           -- Entry point
  +-- .given (getter)             -- Returns GivenBuilder subclass
GivenBuilder                      -- Lists domain objects: .product(), .coupon()
  +-- .product()                  -- Returns DomainObjectBuilder<NeedsWhen>
DomainObjectBuilder<NeedsWhen>    -- .withX() fluent methods, .when/.and getters
  +-- .when                       -- Returns WhenBuilder subclass
WhenBuilder                       -- Lists use cases: .placeOrder()
  +-- .placeOrder()               -- Returns DomainObjectBuilder<NeedsThen>
DomainObjectBuilder<NeedsThen>    -- .withX() fluent methods, .then getter
  +-- .then                       -- Returns ThenBuilder subclass
ThenBuilder                       -- .shouldSucceed(), .order() etc
AssertionBuilder                  -- .hasBasePrice(), .hasQuantity(), .run()
```

### Phantom Types

```dart
sealed class ScenarioState {}
final class NeedsGiven extends ScenarioState {}
final class NeedsWhen extends ScenarioState {}
final class NeedsThen extends ScenarioState {}
final class ReadyToRun extends ScenarioState {}
```

### File Structure

```
test/valenty/features/<feature>/
+-- <feature>_scenario.dart
+-- builders/
|   +-- given/  (GivenBuilder + DomainObjectBuilder<NeedsWhen> per object)
|   +-- when/   (WhenBuilder + DomainObjectBuilder<NeedsThen> per use case)
|   +-- then/   (ThenBuilder + AssertionBuilder)
+-- scenarios/  (test files)
```

## Scaffolding Builders

When asked to scaffold a feature:

1. Read domain models in `lib/` to understand objects and properties
2. Generate FeatureScenario, GivenBuilder, WhenBuilder, ThenBuilder
3. Generate DomainObjectBuilders for each domain object
4. Generate AssertionBuilder for result verification
5. Wire `applyToContext()` to create real domain objects via `TestContext`

### Key Patterns

**DomainObjectBuilder<NeedsWhen> (Given phase):**
- Takes `ScenarioBuilder<NeedsWhen>`, passes `StepPhase.given` to super
- `.withX()` stores value, returns `this`
- `applyToContext()` creates domain object, calls `ctx.set('key', object)`
- `.when` getter: `finalizeStep()` then `addStep<NeedsThen>()`, return WhenBuilder
- `.and` getter: `finalizeStep()`, return new GivenBuilder

**DomainObjectBuilder<NeedsThen> (When phase):**
- Takes `ScenarioBuilder<NeedsThen>`, passes `StepPhase.when` to super
- `applyToContext()` reads Given values via `ctx.get()`, executes use case, stores result
- `.then` getter: `finalizeStep()` then `addStep<ReadyToRun>()`, return ThenBuilder

### TestContext API

```dart
ctx.set<T>(String key, T value)   // Store a value
ctx.get<T>(String key)            // Retrieve typed value (throws StateError if missing)
ctx.has(String key)               // Check if key exists (returns bool)
ctx.clear()                       // Clear all values
```

**Always specify type on get:** `ctx.get<Product>('product')` not `ctx.get('product')`

**Always guard optional values:**
```dart
// CORRECT — handles scenarios with and without coupon:
final discount = ctx.has('couponDiscount')
    ? ctx.get<double>('couponDiscount')
    : 0.0;

// WRONG — crashes when coupon not provided:
final discount = ctx.get<double>('couponDiscount');
```

### Async applyToContext()

When a step needs async work (API calls, DB reads), return `Future<void>` instead of
`void`. The `ScenarioRunner` detects futures and awaits them automatically.

```dart
@override
Future<void> applyToContext(TestContext ctx) async {
  final response = await apiClient.fetchOrder(id: _orderId);
  ctx.set('order', response);
}
```

Sync and async builders mix freely in the same scenario chain. The fluent API,
`.withX()` methods, and `.run()` stay unchanged.

### Common Mistakes to Avoid

- `ctx.get('key')` without type param — returns dynamic, causes cast errors
- `ctx.get<T>('key')` without `ctx.has()` check on optional values — crashes
- Inventing `.hasX()` methods that don't exist — always read builders first
- Mismatched context keys between Given and When — keys must match exactly
- Missing `.run()` at end of chain — test never executes
- `.given()` with parens — it's a getter: `.given`

## Writing Tests

When asked to write tests from QA scenarios:

1. **Always read existing builders first** to know available methods
2. Map English scenario parts to builder methods
3. Use `.given`, `.when`, `.then` as getters (NO parentheses)
4. Use `.and` to chain multiple givens or assertions
5. End every chain with `.run()`

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

## Parameterized Tests

Use `parameterizedTest()` from `package:valenty_dsl` to run one scenario against
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

## Rules

- Never invent builder methods that do not exist
- Never use `.given()`, `.when()`, `.then()` with parentheses -- they are getters
- Always import `package:valenty_dsl/valenty_dsl.dart` in builder files
- Always import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Invalid tests will not compile -- that is the point of the typed DSL

## Onboarding (when user runs `valenty init` or asks to set up Valenty)

Before running any setup commands:

1. **Scan the project first** — check pubspec.yaml, look for `.cursor/`, `.claude/`,
   `.opencode/`, `AGENTS.md` directories. Find domain models in `lib/`.

2. **Present findings** — show the user what AI tools you detected, what domain models
   exist, and what project type it is.

3. **Ask the user** (one question at a time):
   - Which AI clients to generate skill files for (detected vs all)
   - Which features to scaffold builders for (based on domain models found)
   - Confirm installation scope (project root vs specific package in monorepo)

4. **Execute** — run `valenty init`, then `valenty scaffold feature` per chosen feature,
   then `valenty generate skills`.

Do NOT silently auto-detect and proceed. Always confirm choices with the user first.
''';
