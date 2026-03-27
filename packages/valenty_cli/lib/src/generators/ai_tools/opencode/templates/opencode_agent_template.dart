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

### TestContext API

```dart
ctx.set<T>(String key, T value)   // Store value
ctx.get<T>(String key)            // Get typed value (StateError if missing)
ctx.has(String key)               // Check if key exists
```

**Always use type param:** `ctx.get<Product>('product')` not `ctx.get('product')`
**Guard optional values:** `ctx.has('key') ? ctx.get<T>('key') : default`

### Async applyToContext()

For async work (API calls, DB reads), return `Future<void>` instead of `void`.
The runner awaits futures automatically.

```dart
@override
Future<void> applyToContext(TestContext ctx) async {
  final response = await apiClient.fetchOrder(id: _orderId);
  ctx.set('order', response);
}
```

### Common Mistakes

- Missing type on `ctx.get()` — cast errors
- Missing `ctx.has()` on optional values — StateError crash
- Inventing builder methods — read actual files first
- `.given()` with parens — it's a getter: `.given`
- Missing `.run()` — test never executes

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

## Rules

- Never invent builder methods that do not exist
- `.given`, `.when`, `.then` are getters, not method calls
- Always import `package:valenty_dsl/valenty_dsl.dart`
- Always import `package:test/test.dart` in assertion files

## Onboarding

When setting up Valenty (`valenty init`), scan the project first:
1. Detect AI tools (`.claude/`, `.cursor/`, `.opencode/`, `AGENTS.md`)
2. Find domain models in `lib/`
3. Present findings and ask the user which AI clients and features to set up
4. Execute setup commands based on user choices

Always confirm with the user before proceeding.
''';
