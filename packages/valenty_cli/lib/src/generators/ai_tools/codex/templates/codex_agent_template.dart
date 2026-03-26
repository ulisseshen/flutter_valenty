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

## Rules

- Never invent builder methods that do not exist in the code
- Never use `.given()`, `.when()`, `.then()` with parentheses
- Always import `package:valenty_dsl/valenty_dsl.dart` in builder files
- Always import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Invalid tests will not compile -- the compiler enforces correct structure
''';
