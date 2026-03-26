/// Template content for the OpenCode agent file.
///
/// This gets written to `.opencode/agents/valenty-test-writer.md`
/// in the user's project when they run `valenty init` or `valenty generate skills`.
const openCodeAgentTemplate = r'''# Valenty Test Writer

Scaffold typed fluent DSL builders for features and generate compile-time safe
acceptance tests from QA scenarios using Valenty's typed fluent DSL.

## Architecture

The DSL uses phantom types to enforce Given -> When -> Then ordering at compile time.

### Class Hierarchy

```
FeatureScenario<TGiven>           -- Entry point
GivenBuilder                      -- Lists domain objects: .product(), .coupon()
DomainObjectBuilder<NeedsWhen>    -- .withX() fluent config, .when/.and transitions
WhenBuilder                       -- Lists use cases: .placeOrder()
DomainObjectBuilder<NeedsThen>    -- .withX() fluent config, .then transition
ThenBuilder                       -- .shouldSucceed(), .order() assertions
AssertionBuilder                  -- .hasBasePrice(), .hasQuantity(), .run()
```

### File Structure

```
test/valenty/features/<feature>/
+-- <feature>_scenario.dart
+-- builders/given/  (GivenBuilder + DomainObjectBuilder<NeedsWhen>)
+-- builders/when/   (WhenBuilder + DomainObjectBuilder<NeedsThen>)
+-- builders/then/   (ThenBuilder + AssertionBuilder)
+-- scenarios/       (test files)
```

## Scaffolding Builders

1. Read domain models in `lib/`
2. Create FeatureScenario, GivenBuilder, WhenBuilder, ThenBuilder
3. Create DomainObjectBuilder per domain object with `.withX()` methods
4. Wire `applyToContext()` to create real domain objects via `TestContext`

### Key Patterns

**DomainObjectBuilder<NeedsWhen> (Given phase):**
- `.withX()` stores value, returns `this`
- `applyToContext()` creates domain object, calls `ctx.set('key', object)`
- `.when` getter: `finalizeStep()` then `addStep<NeedsThen>()`, return WhenBuilder
- `.and` getter: `finalizeStep()`, return new GivenBuilder

**DomainObjectBuilder<NeedsThen> (When phase):**
- `applyToContext()` reads Given values via `ctx.get()`, executes use case, stores result
- `.then` getter: `finalizeStep()` then `addStep<ReadyToRun>()`, return ThenBuilder

## Writing Tests

1. Always read existing builders first
2. `.given`, `.when`, `.then` are getters (no parentheses)
3. `.and` chains multiple givens or assertions
4. End with `.run()`

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
- `.given`, `.when`, `.then` are getters, not method calls
- Always import `package:valenty_dsl/valenty_dsl.dart`
- Always import `package:test/test.dart` in assertion files
''';
