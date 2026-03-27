/// Template content for the AGENTS.md file.
///
/// This gets written to `AGENTS.md` in the user's project root
/// when they run `valenty init` or `valenty generate skills`.
const codexAgentTemplate = r'''# Valenty: Typed Fluent DSL for Acceptance Testing

## Overview

This project uses **Valenty** (`package:valenty_dsl`) for compile-time safe
acceptance testing. The DSL uses phantom types and fluent builders to enforce
Given -> When -> Then ordering at compile time.

## Architecture

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

## Scaffolding Builders

When scaffolding a feature:

1. Read domain models in `lib/` for objects, properties, and use cases
2. Create FeatureScenario extending `FeatureScenario<TGivenBuilder>`
3. Create GivenBuilder extending `GivenBuilder` with methods per domain object
4. Create DomainObjectBuilder<NeedsWhen> per domain object with `.withX()` methods
5. Create WhenBuilder extending `WhenBuilder` with methods per use case
6. Create DomainObjectBuilder<NeedsThen> per use case with `.withX()` methods
7. Create ThenBuilder extending `ThenBuilder` with assertion methods
8. Create AssertionBuilder extending `AssertionBuilder` with `.hasX()` methods

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

For async work (API calls, DB reads), return `Future<void>` instead of `void`.
The `ScenarioRunner` detects futures and awaits them automatically.

```dart
@override
Future<void> applyToContext(TestContext ctx) async {
  final response = await apiClient.fetchOrder(id: _orderId);
  ctx.set('order', response);
}
```

Sync and async builders mix freely in the same chain — no extra wiring needed.

### Common Mistakes

- `ctx.get('key')` without type param — returns dynamic, causes cast errors
- `ctx.get<T>('key')` on optional values without `ctx.has()` — crashes with StateError
- Inventing `.hasX()` methods — always read actual builders first
- Mismatched context keys between Given and When phases
- Missing `.run()` at end — test never executes
- `.given()` with parens — it's a getter: `.given`

### Key Pattern: Transition Getters

- `.when` on DomainObjectBuilder<NeedsWhen>: `finalizeStep()` then `addStep<NeedsThen>()`
- `.then` on DomainObjectBuilder<NeedsThen>: `finalizeStep()` then `addStep<ReadyToRun>()`
- `.and` on DomainObjectBuilder<NeedsWhen>: `finalizeStep()`, return new GivenBuilder

## Writing Tests

1. Always read existing builders first to know available methods
2. Map English scenarios to builder method chains
3. `.given`, `.when`, `.then` are getters (no parentheses)
4. `.and` chains multiple givens or assertions
5. `.run()` executes the test via `package:test`

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

- Never invent builder methods that do not exist in the code
- Never use `.given()`, `.when()`, `.then()` with parentheses
- Always import `package:valenty_dsl/valenty_dsl.dart` in builder files
- Always import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Invalid tests will not compile -- the compiler enforces correct structure

## Onboarding

When setting up Valenty (`valenty init`), scan the project first:
1. Detect AI tools (`.claude/`, `.cursor/`, `.opencode/`, `AGENTS.md`)
2. Find domain models in `lib/`
3. Present findings and ask the user which AI clients and features to set up
4. Execute setup commands based on user choices

Always confirm with the user before proceeding.
''';
