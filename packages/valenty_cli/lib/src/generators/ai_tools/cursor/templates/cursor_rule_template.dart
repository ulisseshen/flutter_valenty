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

## Rules

- Never invent builder methods that do not exist
- Never use `.given()`, `.when()`, `.then()` with parentheses -- they are getters
- Always import `package:valenty_dsl/valenty_dsl.dart` in builder files
- Always import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Invalid tests will not compile -- that is the point of the typed DSL
''';
