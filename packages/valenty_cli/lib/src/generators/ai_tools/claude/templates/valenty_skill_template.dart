/// Template content for the Claude Code skill file.
///
/// This gets written to `.claude/skills/valenty-test-writer/SKILL.md`
/// in the user's project when they run `valenty init` or `valenty generate skills`.
const valentySkillTemplate = r'''
---
name: valenty-test-writer
description: >
  Scaffold typed fluent DSL builders for features AND generate compile-time safe
  acceptance tests from QA scenarios using Valenty's typed fluent DSL.
trigger: >
  Use when user says "scaffold feature", "scaffold builders", "write test",
  "generate test", "acceptance test", "QA scenario", "test for feature",
  "write scenario", or provides a plain-English Given/When/Then scenario.
---

# Valenty Test Writer & Builder Scaffolder

You scaffold **typed fluent DSL builders** for features and generate **compile-time
safe acceptance tests** from QA scenarios using the Valenty DSL.

The DSL uses phantom types and fluent builders. No strings, no action callbacks.
The IDE guides every step and the compiler catches errors before runtime.

---

## Part A: Scaffold Feature Builders

When the user says something like "scaffold the Order feature for acceptance testing",
you must:

1. **Read the user's domain models** in `lib/` to understand the domain objects,
   their properties, and the use cases.
2. **Generate the complete builder tree** under `test/valenty/features/<feature>/`.

### Builder Architecture

The Valenty DSL has a strict class hierarchy. Each builder extends a base class
from `package:valenty_dsl/valenty_dsl.dart`:

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
import 'package:valenty_dsl/valenty_dsl.dart';

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
import 'package:valenty_dsl/valenty_dsl.dart';

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
import 'package:valenty_dsl/valenty_dsl.dart';

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
import 'package:valenty_dsl/valenty_dsl.dart';

import '<usecase>_when_builder.dart';

class <Feature>WhenBuilder extends WhenBuilder {
  <Feature>WhenBuilder(super.scenario);

  <UseCase>WhenBuilder <useCase>() => <UseCase>WhenBuilder(scenario);
}
```

#### 5. DomainObjectBuilder in When phase (use case builder)

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

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
import 'package:valenty_dsl/valenty_dsl.dart';

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
import 'package:valenty_dsl/valenty_dsl.dart';

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
A fresh context is created for each scenario — no state leaks between tests.

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

When a Given object is optional (e.g., a coupon may or may not be provided),
the When builder MUST check before reading:

```dart
// CORRECT — handles both "with coupon" and "without coupon" scenarios:
final discount = ctx.has('couponDiscount')
    ? ctx.get<double>('couponDiscount')
    : 0.0;

// WRONG — crashes with StateError when no coupon was given:
final discount = ctx.get<double>('couponDiscount');
```

### How applyToContext() Wires Builders to Domain Models

The `TestContext` is a key-value store shared across all steps. The flow is:

1. **Given phase**: DomainObjectBuilders create domain models and store them:
   ```dart
   ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
   ctx.set('couponDiscount', _discount);
   ```

2. **When phase**: Use case builders read Given values and store results:
   ```dart
   final product = ctx.get<Product>('product');
   // Use ctx.has() for optional preconditions:
   final discount = ctx.has('couponDiscount')
       ? ctx.get<double>('couponDiscount')
       : 0.0;
   final order = Order(quantity: _qty, basePrice: product.unitPrice * _qty, ...);
   ctx.set('order', order);
   ```

3. **Then phase**: Assertion builders/methods read results and assert:
   ```dart
   final order = ctx.get<Order>('order');
   expect(order.basePrice, equals(expected));
   ```

### applyToContext() Pattern

Follow this pattern for every `applyToContext()` implementation:

```dart
@override
void applyToContext(TestContext ctx) {
  // 1. READ: Get required preconditions (crash early if missing)
  final product = ctx.get<Product>('product');

  // 2. READ OPTIONAL: Guard optional preconditions with ctx.has()
  final discount = ctx.has('couponDiscount')
      ? ctx.get<double>('couponDiscount')
      : 0.0;

  // 3. EXECUTE: Run the domain logic
  final basePrice = product.unitPrice * _quantity - discount;

  // 4. WRITE: Store the result with a descriptive key
  ctx.set('order', Order(quantity: _quantity, basePrice: basePrice));
}
```

### Async applyToContext() Pattern

When a builder step needs to perform async work (API calls, database reads, file I/O),
override `applyToContext()` as `Future<void>` instead of `void`. The `ScenarioRunner`
automatically detects `Future` return values and awaits them — no extra wiring needed.

```dart
@override
Future<void> applyToContext(TestContext ctx) async {
  // Async operations are fully supported — the runner awaits them.
  final response = await apiClient.fetchOrder(id: _orderId);
  ctx.set('order', response);
}
```

**How it works:** `ScenarioRunner` calls each step's action and checks
`if (result is Future) { await result; }`. This means both sync and async
`applyToContext()` methods work transparently in the same scenario chain.

**When to use async:**
- Calling REST APIs, gRPC services, or GraphQL endpoints
- Reading from databases (Firestore, SQLite, Hive, etc.)
- File system operations or process execution
- Any I/O-bound operation that returns a `Future`

**Full async example (When phase — API call + DB read):**

```dart
class PlaceOrderWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  PlaceOrderWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  PlaceOrderWhenBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  Future<void> applyToContext(TestContext ctx) async {
    final product = ctx.get<Product>('product');

    // Call an API or service — the runner awaits this automatically
    final order = await orderService.place(
      productId: product.id,
      quantity: _quantity,
    );

    ctx.set('order', order);
  }

  // ... .then getter unchanged
}
```

**Key points:**
- The method signature changes from `void` to `Future<void>` and adds `async`
- All `.withX()` methods, `.when`/`.then`/`.and` getters stay exactly the same
- You can mix sync and async builders freely in the same scenario chain
- Tests remain identical — the fluent API and `.run()` are unaffected

**Review checklist:**
- [ ] Every `ctx.get<T>()` has an explicit type parameter
- [ ] Optional values are guarded with `ctx.has()` before `ctx.get()`
- [ ] Context keys used in `ctx.get()` match keys set by earlier phases
- [ ] Result is stored via `ctx.set()` with a key that Then builders expect

### Common LLM Mistakes to Avoid

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

### Scaffolding Checklist

When scaffolding a feature, follow this exact order:

1. Read the domain models in `lib/` to find:
   - Domain objects (e.g., Product, Order, User, Payment)
   - Their properties (name, price, quantity, etc.)
   - Use cases / operations (placeOrder, makePayment, registerUser)
   - Result types (success/failure, computed values)

2. Create the file structure under `test/valenty/features/<feature>/`

3. Generate each file using the templates above, filling in:
   - Domain object names and properties for `.withX()` methods
   - Use case names for WhenBuilder methods
   - Result properties for `.hasX()` assertion methods
   - Correct import paths to domain models

4. Wire `applyToContext()` to create real domain objects

5. Test that the generated code compiles by running `dart analyze`

---

## Part B: Write Acceptance Tests

When the user says something like "write test for: Given a product with unit price $20..."
or provides QA scenarios, you must:

### Step 1: Identify the Feature

Look at the scenario to determine which feature it belongs to. Check if builders
already exist:

```
test/valenty/features/<feature_name>/
+-- <feature>_scenario.dart
+-- builders/given/
+-- builders/when/
+-- builders/then/
+-- scenarios/
```

### Step 2: Read Existing Builders (MANDATORY)

Before writing ANY test, **read the existing builders** to know what methods are
available. This is critical -- you can ONLY use methods that exist on the builders.

**Read these files in order:**
1. `<Feature>Scenario` -- the entry point class name
2. `<Feature>GivenBuilder` -- available domain objects (`.product()`, `.coupon()`)
3. Each `DomainObjectBuilder` in given/ -- `.withX()` methods
4. `<Feature>WhenBuilder` -- available use cases (`.placeOrder()`, `.cancelOrder()`)
5. Each `DomainObjectBuilder` in when/ -- `.withX()` methods for use case params
6. `<Feature>ThenBuilder` -- assertions (`.shouldSucceed()`, `.order()`)
7. Each `AssertionBuilder` in then/ -- `.hasX()` assertion methods

### Step 3: Map the Scenario to Builder Methods

| English Scenario Part | Maps To |
|---|---|
| "Given a product with unit price $20" | `.given.product().withUnitPrice(20.00)` |
| "and a coupon with 10% discount" | `.and.coupon().withDiscount(0.10)` |
| "When an order is placed with quantity 5" | `.when.placeOrder().withQuantity(5)` |
| "Then the order should succeed" | `.then.shouldSucceed()` |
| "And the base price should be $100" | `.and.order().hasBasePrice(100.00)` |

### Step 4: Generate the Test File

```dart
import 'package:test/test.dart';

import '../<feature>_scenario.dart';

void main() {
  group('<Feature> Acceptance Tests', () {
    <Feature>Scenario('should <description>')
        .given
        .<domainObject>()
            .with<Property>(<value>)
        .when
        .<useCase>()
            .with<Input>(<value>)
        .then
        .<assertion>()
        .run();
  });
}
```

---

## Complete Working Example: Order Feature

This is a real, working example from the project. Use it as the reference.

### Domain Models

```dart
// lib/models/product.dart
class Product {
  const Product({required this.name, required this.unitPrice});
  final String name;
  final double unitPrice;
}

// lib/models/order.dart
class Order {
  const Order({required this.quantity, required this.basePrice, required this.success});
  final int quantity;
  final double basePrice;
  final bool success;
}
```

### OrderScenario (entry point)

```dart
// test/valenty/features/order/order_scenario.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import 'builders/given/order_given_builder.dart';

class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
  OrderScenario(super.description);

  @override
  OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return OrderGivenBuilder(scenario);
  }
}
```

### OrderGivenBuilder

```dart
// test/valenty/features/order/builders/given/order_given_builder.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import 'product_given_builder.dart';
import 'coupon_given_builder.dart';

class OrderGivenBuilder extends GivenBuilder {
  OrderGivenBuilder(super.scenario);

  ProductGivenBuilder product() => ProductGivenBuilder(scenario);
  CouponGivenBuilder coupon() => CouponGivenBuilder(scenario);
}
```

### ProductGivenBuilder

```dart
// test/valenty/features/order/builders/given/product_given_builder.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import '../../../../../../lib/models/product.dart';
import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

class ProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'Default Product';
  double _unitPrice = 0;

  ProductGivenBuilder withName(String name) { _name = name; return this; }
  ProductGivenBuilder withUnitPrice(double price) { _unitPrice = price; return this; }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
  }

  OrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderWhenBuilder(next);
  }

  OrderGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderGivenBuilder(finalized);
  }
}
```

### CouponGivenBuilder

```dart
// test/valenty/features/order/builders/given/coupon_given_builder.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

class CouponGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CouponGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _code = 'DEFAULT';
  double _discount = 0;

  CouponGivenBuilder withCode(String code) { _code = code; return this; }
  CouponGivenBuilder withDiscount(double discount) { _discount = discount; return this; }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('couponCode', _code);
    ctx.set('couponDiscount', _discount);
  }

  OrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderWhenBuilder(next);
  }

  OrderGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderGivenBuilder(finalized);
  }
}
```

### OrderWhenBuilder

```dart
// test/valenty/features/order/builders/when/order_when_builder.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import 'place_order_when_builder.dart';

class OrderWhenBuilder extends WhenBuilder {
  OrderWhenBuilder(super.scenario);

  PlaceOrderWhenBuilder placeOrder() => PlaceOrderWhenBuilder(scenario);
}
```

### PlaceOrderWhenBuilder

```dart
// test/valenty/features/order/builders/when/place_order_when_builder.dart
import 'package:valenty_dsl/valenty_dsl.dart';
import '../../../../../../lib/models/order.dart';
import '../../../../../../lib/models/product.dart';
import '../then/order_then_builder.dart';

class PlaceOrderWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  PlaceOrderWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  PlaceOrderWhenBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final product = ctx.get<Product>('product');
    final discount = ctx.has('couponDiscount')
        ? ctx.get<double>('couponDiscount')
        : 0.0;
    final rawPrice = product.unitPrice * _quantity;
    final basePrice = rawPrice - (rawPrice * discount);

    ctx.set('order', Order(
      quantity: _quantity,
      basePrice: basePrice,
      success: _quantity > 0,
    ));
  }

  OrderThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return OrderThenBuilder(next);
  }
}
```

### OrderThenBuilder

```dart
// test/valenty/features/order/builders/then/order_then_builder.dart
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';
import '../../../../../../lib/models/order.dart';
import 'order_assertion_builder.dart';

class OrderThenBuilder extends ThenBuilder {
  OrderThenBuilder(super.scenario);

  OrderThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isTrue, reason: 'Expected order to succeed');
    });
    return OrderThenTerminal(next);
  }

  OrderThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isFalse, reason: 'Expected order to fail');
    });
    return OrderThenTerminal(next);
  }

  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);
}

class OrderThenTerminal {
  OrderThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  OrderAndThenBuilder get and => OrderAndThenBuilder(scenario);
  void run() => ScenarioRunner.run(scenario);
}

class OrderAndThenBuilder extends AndThenBuilder {
  OrderAndThenBuilder(super.scenario);

  OrderAssertionBuilder order() => OrderAssertionBuilder(scenario);
}
```

### OrderAssertionBuilder

```dart
// test/valenty/features/order/builders/then/order_assertion_builder.dart
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';
import '../../../../../../lib/models/order.dart';
import 'order_then_builder.dart';

class OrderAssertionBuilder extends AssertionBuilder {
  OrderAssertionBuilder(super.scenario);

  OrderAssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.basePrice, equals(expected),
          reason: 'Expected base price to be $expected');
    });
    return this;
  }

  OrderAssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.quantity, equals(expected),
          reason: 'Expected quantity to be $expected');
    });
    return this;
  }

  OrderAndThenBuilder get and => OrderAndThenBuilder(currentScenario);
  void run() => ScenarioRunner.run(currentScenario);
}
```

### Test File (the output)

```dart
// test/valenty/features/order/scenarios/order_pricing_test.dart
import 'package:test/test.dart';
import '../order_scenario.dart';

void main() {
  group('Order Pricing', () {
    OrderScenario(
      'should calculate base price as product of unit price and quantity',
    )
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

    OrderScenario('should apply percentage coupon to base price')
        .given
        .product()
        .withUnitPrice(20.00)
        .and
        .coupon()
        .withDiscount(0.10)
        .when
        .placeOrder()
        .withQuantity(5)
        .then
        .order()
        .hasBasePrice(90.00)
        .run();

    OrderScenario('should reject order with zero quantity')
        .given
        .product()
        .withUnitPrice(50.00)
        .when
        .placeOrder()
        .withQuantity(0)
        .then
        .shouldFail()
        .run();
  });
}
```

---

## Rules

### DO:
- **Always read the domain models in `lib/`** before scaffolding builders
- **Always read existing builders** before writing test code
- Use `.given`, `.when`, `.then` as getters (no parentheses)
- Use `.and` to chain multiple givens or multiple assertions
- Use `.run()` at the end to register as a `package:test` test case
- Keep scenario descriptions behavior-focused: "should calculate base price"
- One scenario per business rule
- Create one `.withX()` method per domain model property
- Use `ctx.set()` / `ctx.get()` with consistent string keys for the domain concept
- Import `package:test/test.dart` in ThenBuilder and AssertionBuilder files
- Import `package:valenty_dsl/valenty_dsl.dart` in every builder file

### DON'T:
- **Never invent builder methods** that don't exist in the code
- Never use strings for step descriptions (that's Gherkin, not this DSL)
- Never use action callbacks `action: (ctx) { }` (that's the old API)
- Never skip reading the builders -- you must know what methods are available
- Never write `.given()` with parentheses -- it's a getter: `.given`
- Never write `.when()` with parentheses -- it's a getter: `.when`
- Never write `.then()` with parentheses -- it's a getter: `.then`
- Never create builders without extending the correct base class
- Never forget `.run()` at the end of a scenario chain

### When Builders Don't Exist Yet:

If the scenario references a domain concept with no builder, tell the user you
need to scaffold it first. Offer to create the builder files, then write the tests.

## Parameterized Tests

Use `parameterizedTest()` from `package:valenty_dsl` to run the same Valenty scenario
against multiple input/output combinations. This eliminates copy-paste when a single
business rule needs verification across several data points.

### How parameterizedTest() Works

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

parameterizedTest(
  'test description',
  [
    [arg1, arg2, expected],  // case 1
    [arg1, arg2, expected],  // case 2
  ],
  (params) {
    final a = params[0] as Type;
    final b = params[1] as Type;
    final expected = params[2] as Type;
    // ... test body using a, b, expected
  },
);
```

Each inner list is a test case. The function creates a separate `package:test` test
for every case, labeled `'test description [case N: [values]]'`.

### Using parameterizedTest() with Valenty Scenarios

Combine parameterized data with the fluent DSL to test a business rule across
multiple value combinations in a single, readable block:

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../order_scenario.dart';

void main() {
  group('Order Pricing - parameterized', () {
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
            .given
            .product()
            .withUnitPrice(unitPrice)
            .when
            .placeOrder()
            .withQuantity(quantity)
            .then
            .order()
            .hasBasePrice(expected)
            .run();
      },
    );
  });
}
```

### When to Use parameterizedTest()

- **Boundary testing**: verify behavior at edge values (zero, negative, max)
- **Pricing rules**: same formula, many input/output pairs
- **Validation rules**: valid vs invalid inputs across a matrix
- **Discount tiers**: multiple thresholds producing different results

### Rules for parameterizedTest()

- Import `package:valenty_dsl/valenty_dsl.dart` (it re-exports `parameterizedTest`)
- Each inner list must have the same length and positional meaning
- Cast each `params[i]` to the correct type (`as double`, `as int`, etc.)
- Include a comment after the first case labeling each position
- Use string interpolation in the scenario description to identify which case failed
- Always end the scenario chain with `.run()` inside the callback

---

## Compile-Time Safety

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
''';
