# Valenty DSL Redesign: Typed Fluent Builder Architecture

## Document Purpose

This document is a **complete implementation specification** for redesigning the `valenty_dsl` package from a string-based Gherkin DSL to a **compile-time safe typed fluent builder DSL** following Valentina Jemuovic's approach to acceptance testing.

An implementation agent with NO prior context about this project should be able to execute this entire redesign using only this document.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Framework Layer (valenty_dsl provides)](#2-framework-layer)
3. [User/Generated Layer (CLI scaffolds per feature)](#3-usergenerated-layer)
4. [Complete File-by-File Implementation Spec](#4-complete-file-by-file-implementation-spec)
5. [Complete Test Spec](#5-complete-test-spec)
6. [Example Usage](#6-example-usage)
7. [Migration Notes](#7-migration-notes)
8. [Barrel Export](#8-barrel-export)

---

## 1. Architecture Overview

### 1.1 The Problem with the Current Approach

The current DSL uses **string-based step descriptions** with action callbacks:

```dart
// CURRENT (string-based, breaks at runtime)
scenario('should calculate base price')
  .given('a product with unit price \$20', action: (ctx) { ... })
  .when('an order is placed with quantity 5', action: (ctx) { ... })
  .then('the base price is \$100', action: (ctx) { ... })
  .run();
```

Problems:
- Strings can contain typos — discovered only at runtime
- No IDE autocompletion for domain concepts
- Refactoring a domain concept requires finding and editing every string
- AI code generators can invent nonexistent step descriptions
- Action callbacks are disconnected from the step description

### 1.2 The Target: Typed Fluent Builder Pattern

The DSL itself IS the language. No strings. No descriptions. Just **typed domain methods** that the compiler and IDE enforce:

```dart
// TARGET (typed fluent DSL, zero strings, compile-time safe)
OrderScenario('should calculate base price')
  .given.product()
      .withUnitPrice(20.00)
  .when.placeOrder()
      .withQuantity(5)
  .then.shouldSucceed()
  .and.order()
      .hasBasePrice(100.00)
  .run();
```

### 1.3 Phantom Types for State Enforcement

Phantom types are type parameters that are never instantiated at runtime. They exist only to constrain what methods are available at each point in the builder chain.

```
ScenarioBuilder<NeedsGiven>  --given-->  ScenarioBuilder<NeedsWhen>
ScenarioBuilder<NeedsWhen>   --when-->   ScenarioBuilder<NeedsThen>
ScenarioBuilder<NeedsThen>   --then-->   ScenarioBuilder<ReadyToRun>
ScenarioBuilder<ReadyToRun>  --and-->    ScenarioBuilder<ReadyToRun>
ScenarioBuilder<ReadyToRun>  --run-->    (executes test)
```

The compiler refuses to call `.when` on a `ScenarioBuilder<NeedsGiven>` because the extension that provides `.when` is only defined on `ScenarioBuilder<NeedsWhen>`.

### 1.4 The Critical Design Challenge: Returning from Domain Builders

After `given.product().withUnitPrice(20)`, how does the chain return to allow `.when`?

**Chosen approach: Domain builders carry a back-reference and expose transition methods.**

Every domain object builder (e.g., `ProductBuilder`) holds a reference to the `ScenarioBuilder` it came from. The domain builder exposes `.when`, `.and`, `.then` methods that:
1. Finalize the domain object being built
2. Register it as a step action in the scenario
3. Return the scenario builder in the appropriate next state

This means `.withUnitPrice(20)` returns the same `ProductBuilder` (for more chaining), and that `ProductBuilder` also has `.when` available which triggers the state transition.

**Why this approach:**
- No `.done()` ceremony — the chain flows naturally
- IDE shows both domain methods (`.withName()`) and transition methods (`.when`, `.and`) after each `.withX()`
- Reads like English: `given.product().withUnitPrice(20).when.placeOrder()`
- The transition methods are defined on a shared `DomainObjectBuilder` base class

### 1.5 Two-Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│  FRAMEWORK LAYER (valenty_dsl package on pub.dev)   │
│                                                     │
│  ScenarioState phantom types                        │
│  ScenarioBuilder<S>                                 │
│  GivenBuilder / WhenBuilder / ThenBuilder (base)    │
│  DomainObjectBuilder<TParent>                       │
│  AssertionBuilder<TParent>                          │
│  ScenarioRunner                                     │
│  TestContext                                        │
│  Channel / ChannelType                              │
│  StepRecord (replaces old Step)                     │
│  Annotations                                        │
├─────────────────────────────────────────────────────┤
│  USER / GENERATED LAYER (per feature)               │
│                                                     │
│  OrderGivenBuilder extends GivenBuilder             │
│  OrderWhenBuilder extends WhenBuilder               │
│  OrderThenBuilder extends ThenBuilder               │
│  ProductBuilder extends DomainObjectBuilder         │
│  CouponBuilder extends DomainObjectBuilder          │
│  OrderAssertionBuilder extends AssertionBuilder     │
│  OrderScenario (entry point factory)                │
└─────────────────────────────────────────────────────┘
```

### 1.6 How `given`, `when`, `then` Work as Getters

In each `ScenarioBuilder` state, the transition keywords (`given`, `when`, `then`, `and`) are **getters** that return the appropriate phase builder. This is what makes the syntax read naturally:

```dart
// `given` is a getter that returns GivenBuilder
// `product()` is a method on the user's OrderGivenBuilder
scenario.given.product().withUnitPrice(20)
```

The user's `OrderGivenBuilder` extends the framework's `GivenBuilder` and adds domain methods like `product()`, `coupon()`, etc.

---

## 2. Framework Layer

This section specifies every class the `valenty_dsl` package provides. These are the framework building blocks that all projects depend on.

### 2.1 Phantom Types (`phantom_types.dart`)

**Keep as-is.** The existing phantom types are correct:

```dart
sealed class ScenarioState {}
final class NeedsGiven extends ScenarioState {}
final class NeedsWhen extends ScenarioState {}
final class NeedsThen extends ScenarioState {}
final class ReadyToRun extends ScenarioState {}
```

### 2.2 TestContext (`test_context.dart`)

**Keep as-is.** The key-value context for passing data between steps is fine.

### 2.3 StepRecord (`step_record.dart`) — Replaces old `step.dart`

The old `Step` class stored string descriptions and action callbacks. The new `StepRecord` stores structured step data without strings:

```dart
/// The phase of a scenario step.
enum StepPhase { given, when, then, and }

/// A recorded step action in a scenario.
///
/// Unlike the old Step class, StepRecord does not store string descriptions.
/// The action itself IS the step — methods on typed builders are the actions.
final class StepRecord {
  const StepRecord({
    required this.phase,
    required this.action,
    this.description,
  });

  /// Which phase this step belongs to.
  final StepPhase phase;

  /// The action to execute. Receives [TestContext], may return Future.
  final dynamic Function(TestContext ctx) action;

  /// Optional human-readable description for reporting/logging.
  /// Auto-generated from the builder method names, NOT user-supplied strings.
  final String? description;
}
```

### 2.4 ScenarioBuilder (`scenario_builder.dart`) — Replaces old `scenario.dart`

This is the core entry point. It holds the scenario state and collected steps. The type parameter `S` is the phantom type that controls which methods are available.

```dart
import 'package:meta/meta.dart';

import 'phantom_types.dart';
import 'step_record.dart';
import 'test_context.dart';

/// The core scenario builder with compile-time state tracking.
///
/// The type parameter [S] is a phantom type that determines which
/// transition methods (given, when, then, and, run) are available.
///
/// Users never instantiate this directly. Instead, they create a
/// feature-specific scenario class that wraps this builder.
class ScenarioBuilder<S extends ScenarioState> {
  ScenarioBuilder._({
    required String description,
    required List<StepRecord> steps,
    required TestContext context,
  })  : _description = description,
        _steps = List.unmodifiable(steps),
        _context = context;

  final String _description;
  final List<StepRecord> _steps;
  final TestContext _context;

  /// The scenario description (for test registration).
  String get description => _description;

  /// All recorded steps so far.
  List<StepRecord> get steps => _steps;

  /// The shared test context.
  TestContext get context => _context;

  /// Create a new scenario builder in the [NeedsGiven] state.
  static ScenarioBuilder<NeedsGiven> create(String description) {
    return ScenarioBuilder<NeedsGiven>._(
      description: description,
      steps: const [],
      context: TestContext(),
    );
  }

  /// Internal: transition to the next state with an additional step.
  @internal
  ScenarioBuilder<T> addStep<T extends ScenarioState>(StepRecord step) {
    return ScenarioBuilder<T>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }

  /// Internal: add a step without changing state.
  @internal
  ScenarioBuilder<S> appendStep(StepRecord step) {
    return ScenarioBuilder<S>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }
}
```

### 2.5 GivenBuilder (`given_builder.dart`)

The base class for the Given phase. Users extend this to add domain object methods.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for the Given phase of a scenario.
///
/// Subclass this to define domain-specific precondition methods.
///
/// Example:
/// ```dart
/// class OrderGivenBuilder extends GivenBuilder {
///   OrderGivenBuilder(super.scenario);
///
///   ProductBuilder product() {
///     return ProductBuilder(scenario);
///   }
/// }
/// ```
abstract class GivenBuilder {
  GivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the scenario builder (for subclasses and domain builders).
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
```

### 2.6 WhenBuilder (`when_builder.dart`)

The base class for the When phase. Users extend this to add use case / action methods.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for the When phase of a scenario.
///
/// Subclass this to define domain-specific action/use-case methods.
///
/// Example:
/// ```dart
/// class OrderWhenBuilder extends WhenBuilder {
///   OrderWhenBuilder(super.scenario);
///
///   PlaceOrderBuilder placeOrder() {
///     return PlaceOrderBuilder(scenario);
///   }
/// }
/// ```
abstract class WhenBuilder {
  WhenBuilder(this._scenario);

  final ScenarioBuilder<NeedsThen> _scenario;

  /// Access the scenario builder (for subclasses and action builders).
  ScenarioBuilder<NeedsThen> get scenario => _scenario;
}
```

### 2.7 ThenBuilder (`then_builder.dart`)

The base class for the Then phase. Users extend this to add assertion methods.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for the Then phase of a scenario.
///
/// Subclass this to define domain-specific assertion methods.
///
/// Example:
/// ```dart
/// class OrderThenBuilder extends ThenBuilder {
///   OrderThenBuilder(super.scenario);
///
///   OrderAssertionBuilder order() {
///     return OrderAssertionBuilder(scenario);
///   }
///
///   ScenarioBuilder<ReadyToRun> shouldSucceed() {
///     return addAssertion((ctx) {
///       final result = ctx.get<bool>('success');
///       expect(result, isTrue);
///     });
///   }
/// }
/// ```
abstract class ThenBuilder {
  ThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the scenario builder (for subclasses and assertion builders).
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Helper: register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ScenarioBuilder<ReadyToRun> addAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }
}
```

### 2.8 AndGivenBuilder (`and_given_builder.dart`)

For `.and` after a Given phase (additional preconditions):

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';

/// Base class for the And phase after Given (additional preconditions).
///
/// This is structurally identical to [GivenBuilder] but exists as a
/// separate type so users can customize what `.and` offers after Given
/// vs. what `.given` offers initially (though typically they are the same).
///
/// By default, feature scenarios wire `.and` (in NeedsWhen) to return
/// the same builder type as `.given`.
abstract class AndGivenBuilder {
  AndGivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the scenario builder.
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
```

### 2.9 AndThenBuilder (`and_then_builder.dart`)

For `.and` after a Then phase (additional assertions):

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for the And phase after Then (additional assertions).
///
/// By default, feature scenarios wire `.and` (in ReadyToRun) to return
/// the same builder type as `.then`.
abstract class AndThenBuilder {
  AndThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the scenario builder.
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Helper: register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ScenarioBuilder<ReadyToRun> addAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.and,
        action: action,
        description: description,
      ),
    );
  }
}
```

### 2.10 DomainObjectBuilder (`domain_object_builder.dart`)

Base class for fluent domain object builders used in the Given and When phases. This is the key class that solves the "return to scenario" problem.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for fluent domain object builders.
///
/// Domain object builders are used in the Given and When phases to
/// configure preconditions and actions with fluent `.withX()` methods.
///
/// The type parameter [TParent] is the phantom type of the scenario
/// builder that this domain object builder will return to when a
/// transition method (`.when`, `.then`, `.and`) is called.
///
/// Every `.withX()` method returns `this` (the same builder) for chaining.
/// Transition methods (`.when`, `.then`, `.and`) finalize the builder,
/// register the step, and return the scenario in the next state.
///
/// Example (Given phase, TParent = NeedsWhen):
/// ```dart
/// class ProductBuilder extends DomainObjectBuilder<NeedsWhen> {
///   ProductBuilder(super.scenario, super.phase);
///
///   double _unitPrice = 0;
///   String _name = 'Default Product';
///
///   ProductBuilder withUnitPrice(double price) {
///     _unitPrice = price;
///     return this;
///   }
///
///   ProductBuilder withName(String name) {
///     _name = name;
///     return this;
///   }
///
///   @override
///   void applyToContext(TestContext ctx) {
///     ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
///   }
/// }
/// ```
abstract class DomainObjectBuilder<TParent extends ScenarioState> {
  DomainObjectBuilder(this._scenario, this._phase);

  final ScenarioBuilder<TParent> _scenario;
  final StepPhase _phase;

  /// Apply this builder's configured values to the test context.
  ///
  /// Subclasses override this to store their domain object in the context.
  void applyToContext(TestContext ctx);

  /// Finalize this builder and return the scenario with the step recorded.
  ScenarioBuilder<TParent> _finalize() {
    return _scenario.appendStep(
      StepRecord(
        phase: _phase,
        action: (ctx) => applyToContext(ctx),
      ),
    );
  }
}

/// Extension providing `.when` transition on domain object builders in the
/// Given phase (where TParent = NeedsWhen).
///
/// This is what allows: `given.product().withUnitPrice(20).when`
extension DomainObjectWhenTransition on DomainObjectBuilder<NeedsWhen> {
  /// Finalize this domain object, register its step, and transition
  /// to the When phase.
  ///
  /// The returned [ScenarioBuilder<NeedsThen>] is typically wrapped
  /// by the feature's WhenBuilder. Feature scenarios override this
  /// to return their specific WhenBuilder.
  ScenarioBuilder<NeedsThen> get whenScenario {
    final finalized = _finalize();
    return finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
  }
}

/// Extension providing `.and` transition on domain object builders in the
/// Given phase (where TParent = NeedsWhen).
///
/// This is what allows: `given.product().withUnitPrice(20).and`
extension DomainObjectAndGivenTransition on DomainObjectBuilder<NeedsWhen> {
  /// Finalize this domain object and stay in the Given phase
  /// for additional preconditions.
  ScenarioBuilder<NeedsWhen> get andScenario {
    return _finalize();
  }
}

/// Extension providing `.then` transition on domain object builders in the
/// When phase (where TParent = NeedsThen).
///
/// This is what allows: `when.placeOrder().withQuantity(5).then`
extension DomainObjectThenTransition on DomainObjectBuilder<NeedsThen> {
  /// Finalize this domain object, register its step, and transition
  /// to the Then phase.
  ScenarioBuilder<ReadyToRun> get thenScenario {
    final finalized = _finalize();
    return finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
  }
}
```

### 2.11 AssertionBuilder (`assertion_builder.dart`)

Base class for fluent assertion builders used in the Then and And phases.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';
import 'test_context.dart';

/// Base class for fluent assertion builders.
///
/// Assertion builders are used in the Then phase to verify outcomes
/// with fluent `.hasX()` methods.
///
/// Each `.hasX()` method registers an assertion step AND returns the
/// same builder for further assertion chaining.
///
/// Transition methods (`.and`, `.run`) finalize and move on.
///
/// Example:
/// ```dart
/// class OrderAssertionBuilder extends AssertionBuilder {
///   OrderAssertionBuilder(super.scenario);
///
///   OrderAssertionBuilder hasBasePrice(double expected) {
///     addAssertionStep((ctx) {
///       final order = ctx.get<Order>('order');
///       expect(order.basePrice, equals(expected));
///     });
///     return this;
///   }
///
///   OrderAssertionBuilder hasStatus(OrderStatus expected) {
///     addAssertionStep((ctx) {
///       final order = ctx.get<Order>('order');
///       expect(order.status, equals(expected));
///     });
///     return this;
///   }
/// }
/// ```
abstract class AssertionBuilder {
  AssertionBuilder(this._scenario);

  ScenarioBuilder<ReadyToRun> _scenario;

  /// Register an assertion step. Call this from `.hasX()` methods.
  void addAssertionStep(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    _scenario = _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }

  /// Get the current scenario builder (after all assertions registered).
  ScenarioBuilder<ReadyToRun> get currentScenario => _scenario;
}
```

### 2.12 ScenarioRunner (`scenario_runner.dart`)

Executes the built scenario as a test.

```dart
import 'package:test/test.dart' as test_pkg;

import 'phantom_types.dart';
import 'scenario_builder.dart';

/// Executes a completed scenario as a test.
///
/// This is used via the `.run()` extension on [ScenarioBuilder<ReadyToRun>].
class ScenarioRunner {
  const ScenarioRunner._();

  /// Run a scenario as a `package:test` test case.
  static void run(ScenarioBuilder<ReadyToRun> scenario) {
    test_pkg.test(scenario.description, () async {
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
      }
    });
  }

  /// Run a scenario as a `package:test` test case with a specific channel.
  static void runWithChannel(
    ScenarioBuilder<ReadyToRun> scenario, {
    required String channelName,
  }) {
    test_pkg.test('[$channelName] ${scenario.description}', () async {
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
      }
    });
  }
}
```

### 2.13 Scenario Extensions (`scenario_extensions.dart`)

Extensions on `ScenarioBuilder` for each phantom type state. These provide the `.run()` method and direct `.given()` / `.when()` / `.then()` for simple inline usage.

```dart
import 'package:test/test.dart' as test_pkg;

import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'scenario_runner.dart';
import 'step_record.dart';

/// Extension on [ScenarioBuilder<ReadyToRun>] — provides `.run()` and `.and`.
extension ReadyToRunExtension on ScenarioBuilder<ReadyToRun> {
  /// Execute this scenario as a test.
  void run() {
    ScenarioRunner.run(this);
  }

  /// Execute this scenario as a test with a specific channel.
  void runWithChannel(String channelName) {
    ScenarioRunner.runWithChannel(this, channelName: channelName);
  }
}
```

### 2.14 FeatureScenario (`feature_scenario.dart`)

Abstract base class that feature-specific scenarios extend. This wires up the `given`, `when`, `then`, `and` getters with the user's custom builders.

```dart
import 'phantom_types.dart';
import 'scenario_builder.dart';
import 'step_record.dart';

/// Abstract base for feature-specific scenario entry points.
///
/// Subclass this for each feature. The type parameters specify which
/// custom builder classes to use for each phase.
///
/// Example:
/// ```dart
/// class OrderScenario extends FeatureScenario<
///     OrderGivenBuilder, OrderWhenBuilder, OrderThenBuilder> {
///   OrderScenario(super.description);
///
///   @override
///   OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> s) =>
///       OrderGivenBuilder(s);
///   @override
///   OrderWhenBuilder createWhenBuilder(ScenarioBuilder<NeedsThen> s) =>
///       OrderWhenBuilder(s);
///   @override
///   OrderThenBuilder createThenBuilder(ScenarioBuilder<ReadyToRun> s) =>
///       OrderThenBuilder(s);
/// }
/// ```
abstract class FeatureScenario<TGiven, TWhen, TThen> {
  FeatureScenario(String description)
      : _builder = ScenarioBuilder.create(description);

  final ScenarioBuilder<NeedsGiven> _builder;

  /// Create the feature-specific Given builder.
  TGiven createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario);

  /// Create the feature-specific When builder.
  TWhen createWhenBuilder(ScenarioBuilder<NeedsThen> scenario);

  /// Create the feature-specific Then builder.
  TThen createThenBuilder(ScenarioBuilder<ReadyToRun> scenario);

  /// Transition to the Given phase. Returns the feature's GivenBuilder.
  TGiven get given {
    final nextState = _builder.addStep<NeedsWhen>(
      StepRecord(phase: StepPhase.given, action: (_) {}),
    );
    return createGivenBuilder(nextState);
  }
}
```

### 2.15 Updated Annotations (`annotations.dart`)

Keep the existing annotations and add `ChannelType`:

```dart
/// Marks a test class as belonging to specific channels.
class Channel {
  const Channel(this.types);
  final Set<ChannelType> types;
}

/// Available test channels.
enum ChannelType {
  ui,
  api,
  cli,
}

/// Marks a test as belonging to a specific pyramid level.
class PyramidLevel {
  const PyramidLevel(this.level);
  final String level;
}

/// Marks a test class as testing a specific feature.
class Feature {
  const Feature(this.name);
  final String name;
}
```

---

## 3. User/Generated Layer

This section specifies what the CLI scaffolds when a user runs `valenty scaffold feature order`. These are the files that live in the USER's project, not in the `valenty_dsl` package.

### 3.1 How Domain Builders Connect Back to the Scenario

The critical flow is:

```
OrderScenario('...')
  .given                          → returns OrderGivenBuilder
  .product()                      → returns ProductGivenBuilder (holds ScenarioBuilder<NeedsWhen>)
  .withUnitPrice(20)              → returns ProductGivenBuilder (same instance, fluent)
  .when                           → finalizes ProductGivenBuilder, returns OrderWhenBuilder
  .placeOrder()                   → returns PlaceOrderWhenBuilder (holds ScenarioBuilder<NeedsThen>)
  .withQuantity(5)                → returns PlaceOrderWhenBuilder (same instance, fluent)
  .then                           → finalizes PlaceOrderWhenBuilder, returns OrderThenBuilder
  .shouldSucceed()                → registers assertion, returns ScenarioBuilder<ReadyToRun>
  .and                            → returns OrderAndThenBuilder
  .order()                        → returns OrderAssertionBuilder
  .hasBasePrice(100.00)           → registers assertion, returns OrderAssertionBuilder
  .run()                          → executes all steps via ScenarioRunner
```

### 3.2 Generated File Structure (per feature)

When `valenty scaffold feature order` runs, it generates:

```
lib/test_dsl/order/
  order_scenario.dart             — The entry point: OrderScenario class
  given/
    order_given_builder.dart      — GivenBuilder with domain object methods
    product_given_builder.dart    — DomainObjectBuilder for Product in Given
    coupon_given_builder.dart     — DomainObjectBuilder for Coupon in Given
  when/
    order_when_builder.dart       — WhenBuilder with action methods
    place_order_when_builder.dart — DomainObjectBuilder for PlaceOrder in When
  then/
    order_then_builder.dart       — ThenBuilder with assertion methods
    order_assertion_builder.dart  — AssertionBuilder for Order assertions
```

### 3.3 Scaffolded Code Templates

These templates show what the CLI generates. The user then fills in the domain logic.

#### OrderScenario (entry point)

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import 'given/order_given_builder.dart';
import 'when/order_when_builder.dart';
import 'then/order_then_builder.dart';

/// Scenario entry point for the Order feature.
///
/// Usage:
/// ```dart
/// OrderScenario('should calculate base price')
///   .given.product().withUnitPrice(20.00)
///   .when.placeOrder().withQuantity(5)
///   .then.shouldSucceed()
///   .run();
/// ```
class OrderScenario {
  OrderScenario(String description)
      : _builder = ScenarioBuilder.create(description);

  final ScenarioBuilder<NeedsGiven> _builder;

  /// Start the Given phase.
  OrderGivenBuilder get given {
    final nextState = _builder.addStep<NeedsWhen>(
      StepRecord(phase: StepPhase.given, action: (_) {}),
    );
    return OrderGivenBuilder(nextState);
  }
}
```

#### OrderGivenBuilder

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import 'product_given_builder.dart';
import 'coupon_given_builder.dart';

/// Given-phase builder for the Order feature.
///
/// Provides domain object precondition methods.
class OrderGivenBuilder extends GivenBuilder {
  OrderGivenBuilder(super.scenario);

  /// Set up a product precondition.
  ProductGivenBuilder product() {
    return ProductGivenBuilder(scenario);
  }

  /// Set up a coupon precondition.
  CouponGivenBuilder coupon() {
    return CouponGivenBuilder(scenario);
  }
}
```

#### ProductGivenBuilder

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

/// Fluent builder for configuring a Product in the Given phase.
class ProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'Default Product';
  double _unitPrice = 0;

  /// Set the product name.
  ProductGivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  /// Set the product unit price.
  ProductGivenBuilder withUnitPrice(double price) {
    _unitPrice = price;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // Store the product data in context.
    // The user fills in their actual domain object creation here.
    ctx.set('product_name', _name);
    ctx.set('product_unit_price', _unitPrice);
  }

  /// Transition to the When phase.
  OrderWhenBuilder get when {
    final finalized = _finalize();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderWhenBuilder(next);
  }

  /// Add another Given precondition.
  OrderGivenBuilder get and {
    final finalized = _finalize();
    return OrderGivenBuilder(finalized);
  }
}
```

**IMPORTANT:** The `_finalize()` method is private in the base class `DomainObjectBuilder`. For the generated code to call it, we need to make it protected. In Dart, there is no `protected` keyword, so we use `@protected` from `package:meta` and make it a public method with a `@visibleForOverriding` or we use a different approach.

**Resolution:** We make `finalize()` a public method on `DomainObjectBuilder` with `@internal` annotation (since it should only be called by generated builders, not by end users). The method name will be `finalizeStep()`.

Updated `DomainObjectBuilder`:

```dart
/// Finalize this builder: register the step with the scenario and
/// return the updated scenario.
ScenarioBuilder<TParent> finalizeStep() {
  return _scenario.appendStep(
    StepRecord(
      phase: _phase,
      action: (ctx) => applyToContext(ctx),
    ),
  );
}
```

And `ProductGivenBuilder.when` becomes:

```dart
OrderWhenBuilder get when {
  final finalized = finalizeStep();
  final next = finalized.addStep<NeedsThen>(
    StepRecord(phase: StepPhase.when, action: (_) {}),
  );
  return OrderWhenBuilder(next);
}
```

#### CouponGivenBuilder

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

/// Fluent builder for configuring a Coupon in the Given phase.
class CouponGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CouponGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _code = '';
  double _discountPercent = 0;

  /// Set the coupon code.
  CouponGivenBuilder withCode(String code) {
    _code = code;
    return this;
  }

  /// Set the discount percentage.
  CouponGivenBuilder withDiscountPercent(double percent) {
    _discountPercent = percent;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('coupon_code', _code);
    ctx.set('coupon_discount_percent', _discountPercent);
  }

  /// Transition to the When phase.
  OrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderWhenBuilder(next);
  }

  /// Add another Given precondition.
  OrderGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderGivenBuilder(finalized);
  }
}
```

#### OrderWhenBuilder

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import 'place_order_when_builder.dart';

/// When-phase builder for the Order feature.
///
/// Provides use case / action methods.
class OrderWhenBuilder extends WhenBuilder {
  OrderWhenBuilder(super.scenario);

  /// Configure a "place order" action.
  PlaceOrderWhenBuilder placeOrder() {
    return PlaceOrderWhenBuilder(scenario);
  }
}
```

#### PlaceOrderWhenBuilder

```dart
import 'package:valenty_dsl/valenty_dsl.dart';

import '../then/order_then_builder.dart';

/// Fluent builder for configuring the PlaceOrder action in the When phase.
class PlaceOrderWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  PlaceOrderWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  /// Set the order quantity.
  PlaceOrderWhenBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // Execute the "place order" use case.
    // The user fills in their actual business logic invocation here.
    final unitPrice = ctx.get<double>('product_unit_price');
    final basePrice = unitPrice * _quantity;
    ctx.set('order_quantity', _quantity);
    ctx.set('order_base_price', basePrice);
    ctx.set('success', true);
  }

  /// Transition to the Then phase.
  OrderThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return OrderThenBuilder(next);
  }
}
```

#### OrderThenBuilder

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'order_assertion_builder.dart';

/// Then-phase builder for the Order feature.
///
/// Provides assertion and assertion-object methods.
class OrderThenBuilder extends ThenBuilder {
  OrderThenBuilder(super.scenario);

  /// Assert that the operation succeeded.
  _OrderThenTerminal shouldSucceed() {
    final next = addAssertion((ctx) {
      final result = ctx.get<bool>('success');
      expect(result, isTrue, reason: 'Expected operation to succeed');
    }, description: 'should succeed');
    return _OrderThenTerminal(next);
  }

  /// Assert that the operation failed.
  _OrderThenTerminal shouldFail() {
    final next = addAssertion((ctx) {
      final result = ctx.get<bool>('success');
      expect(result, isFalse, reason: 'Expected operation to fail');
    }, description: 'should fail');
    return _OrderThenTerminal(next);
  }

  /// Start asserting on the order object.
  OrderAssertionBuilder order() {
    return OrderAssertionBuilder(scenario);
  }
}

/// Terminal object after a Then assertion, providing `.and` and `.run()`.
class _OrderThenTerminal {
  _OrderThenTerminal(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Add more assertions.
  OrderAndThenBuilder get and => OrderAndThenBuilder(_scenario);

  /// Execute the scenario.
  void run() => ScenarioRunner.run(_scenario);
}

/// And-phase builder after Then for additional assertions.
class OrderAndThenBuilder extends AndThenBuilder {
  OrderAndThenBuilder(super.scenario);

  /// Assert on the order object.
  OrderAssertionBuilder order() {
    return OrderAssertionBuilder(scenario);
  }

  /// Assert that the operation succeeded.
  _OrderThenTerminal shouldSucceed() {
    final next = addAssertion((ctx) {
      final result = ctx.get<bool>('success');
      expect(result, isTrue, reason: 'Expected operation to succeed');
    }, description: 'should succeed');
    return _OrderThenTerminal(next);
  }
}
```

#### OrderAssertionBuilder

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

/// Fluent assertion builder for Order properties.
class OrderAssertionBuilder extends AssertionBuilder {
  OrderAssertionBuilder(super.scenario);

  /// Assert the base price of the order.
  OrderAssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final basePrice = ctx.get<double>('order_base_price');
      expect(basePrice, equals(expected),
          reason: 'Expected base price to be $expected');
    }, description: 'has base price $expected');
    return this;
  }

  /// Assert the quantity of the order.
  OrderAssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final quantity = ctx.get<int>('order_quantity');
      expect(quantity, equals(expected),
          reason: 'Expected quantity to be $expected');
    }, description: 'has quantity $expected');
    return this;
  }

  /// Transition to And for more assertions.
  OrderAndThenBuilder get and => OrderAndThenBuilder(currentScenario);

  /// Execute the scenario.
  void run() => ScenarioRunner.run(currentScenario);
}
```

---

## 4. Complete File-by-File Implementation Spec

This section lists every file in the redesigned `valenty_dsl/lib/src/` directory with complete, compilable Dart code.

### Directory Structure

```
valenty_dsl/
  lib/
    valenty_dsl.dart                          — Barrel export
    src/
      core/
        phantom_types.dart                    — KEEP (unchanged)
        test_context.dart                     — KEEP (unchanged)
        step_record.dart                      — NEW (replaces step.dart)
        scenario_builder.dart                 — NEW (replaces scenario.dart)
        scenario_extensions.dart              — REWRITE
        annotations.dart                      — REWRITE (add ChannelType enum)
      builders/
        given_builder.dart                    — NEW
        when_builder.dart                     — NEW
        then_builder.dart                     — NEW
        and_given_builder.dart                — NEW
        and_then_builder.dart                 — NEW
        domain_object_builder.dart            — NEW
        assertion_builder.dart                — NEW
        feature_scenario.dart                 — NEW
      runner/
        scenario_runner.dart                  — NEW
      channels/
        channel.dart                          — KEEP
        ui_channel.dart                       — KEEP
        api_channel.dart                      — KEEP
        cli_channel.dart                      — KEEP
      drivers/
        driver.dart                           — KEEP
        flutter_widget_driver.dart            — KEEP
        http_driver.dart                      — KEEP
      fixtures/
        fixture_base.dart                     — KEEP
        creation_methods.dart                 — KEEP
        test_data_builder.dart                — KEEP
      matchers/
        valenty_matchers.dart                 — KEEP
        delta_assertion.dart                  — KEEP
      helpers/
        parameterized_test.dart               — KEEP
        guard_assertion.dart                  — KEEP
```

### 4.1 `lib/src/core/phantom_types.dart` — KEEP UNCHANGED

```dart
/// Phantom types for compile-time scenario state enforcement.
/// These types are never instantiated - they exist only as type parameters.
sealed class ScenarioState {}

/// Initial state - only `given()` is available.
final class NeedsGiven extends ScenarioState {}

/// After given - `when()` and `and()` (for additional givens) are available.
final class NeedsWhen extends ScenarioState {}

/// After when - `then()` is available.
final class NeedsThen extends ScenarioState {}

/// After then - `run()` and `and()` (for additional assertions) are available.
final class ReadyToRun extends ScenarioState {}
```

### 4.2 `lib/src/core/test_context.dart` — KEEP UNCHANGED

```dart
/// Key-value context passed between Given/When/Then steps.
class TestContext {
  final Map<String, dynamic> _values = {};

  /// Store a value by key.
  void set<T>(String key, T value) {
    _values[key] = value;
  }

  /// Retrieve a typed value by key.
  T get<T>(String key) {
    final value = _values[key];
    if (value == null) {
      throw StateError('No value found for key "$key" in TestContext.');
    }
    if (value is! T) {
      throw StateError(
        'Value for key "$key" is ${value.runtimeType}, expected $T.',
      );
    }
    return value;
  }

  /// Check if a key exists.
  bool has(String key) => _values.containsKey(key);

  /// Clear all values.
  void clear() => _values.clear();
}
```

### 4.3 `lib/src/core/step_record.dart` — NEW

```dart
import 'test_context.dart';

/// The phase of a scenario step.
enum StepPhase {
  /// Precondition setup.
  given,

  /// Action / event being tested.
  when,

  /// Assertion / expected outcome.
  then,

  /// Additional precondition or assertion (continuation of previous phase).
  and,
}

/// A recorded step action in a scenario.
///
/// Unlike the old string-based Step class, StepRecord stores structured
/// actions without requiring user-supplied description strings.
/// The action itself IS the step — typed builder methods are the actions.
final class StepRecord {
  const StepRecord({
    required this.phase,
    required this.action,
    this.description,
  });

  /// Which phase this step belongs to.
  final StepPhase phase;

  /// The action to execute. Receives [TestContext], may return Future.
  final dynamic Function(TestContext ctx) action;

  /// Optional human-readable description for reporting/logging.
  /// This is auto-generated from builder method names, NOT user-supplied.
  final String? description;
}
```

### 4.4 `lib/src/core/scenario_builder.dart` — NEW

```dart
import 'phantom_types.dart';
import 'step_record.dart';
import 'test_context.dart';

/// The core scenario builder with compile-time state tracking.
///
/// The type parameter [S] is a phantom type that determines which
/// transition methods (given, when, then, and, run) are available.
///
/// Users never instantiate this directly. Instead, they create a
/// feature-specific scenario class that uses this builder internally.
class ScenarioBuilder<S extends ScenarioState> {
  ScenarioBuilder._({
    required String description,
    required List<StepRecord> steps,
    required TestContext context,
  })  : _description = description,
        _steps = List.unmodifiable(steps),
        _context = context;

  final String _description;
  final List<StepRecord> _steps;
  final TestContext _context;

  /// The scenario description (used for test registration).
  String get description => _description;

  /// All recorded steps so far (immutable list).
  List<StepRecord> get steps => _steps;

  /// The shared test context passed to all steps.
  TestContext get context => _context;

  /// Create a new scenario builder in the [NeedsGiven] state.
  static ScenarioBuilder<NeedsGiven> create(String description) {
    return ScenarioBuilder<NeedsGiven>._(
      description: description,
      steps: const [],
      context: TestContext(),
    );
  }

  /// Add a step and transition to a new state [T].
  ///
  /// This changes the phantom type, enabling different methods
  /// on the returned builder.
  ScenarioBuilder<T> addStep<T extends ScenarioState>(StepRecord step) {
    return ScenarioBuilder<T>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }

  /// Add a step without changing state.
  ///
  /// Used when appending additional steps within the same phase
  /// (e.g., multiple assertions in the Then phase).
  ScenarioBuilder<S> appendStep(StepRecord step) {
    return ScenarioBuilder<S>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }
}
```

### 4.5 `lib/src/core/scenario_extensions.dart` — REWRITE

```dart
import 'package:test/test.dart' as test_pkg;

import 'phantom_types.dart';
import 'scenario_builder.dart';
import '../runner/scenario_runner.dart';

/// Extension on [ScenarioBuilder<ReadyToRun>] providing `.run()`.
extension ReadyToRunExtension on ScenarioBuilder<ReadyToRun> {
  /// Execute this scenario as a `package:test` test case.
  void run() {
    ScenarioRunner.run(this);
  }

  /// Execute this scenario as a test with a specific channel label.
  void runWithChannel(String channelName) {
    ScenarioRunner.runWithChannel(this, channelName: channelName);
  }
}
```

### 4.6 `lib/src/core/annotations.dart` — REWRITE

```dart
/// Available test channel types for multi-channel testing.
enum ChannelType {
  /// UI-based interactions (e.g., Flutter widgets, web UI).
  ui,

  /// API-based interactions (e.g., REST, GraphQL).
  api,

  /// CLI-based interactions.
  cli,
}

/// Marks a test class as supporting specific channels.
///
/// Example:
/// ```dart
/// @Channel({ChannelType.ui, ChannelType.api})
/// class OrderAcceptanceTest { ... }
/// ```
class Channel {
  const Channel(this.types);

  /// The set of channel types this test supports.
  final Set<ChannelType> types;
}

/// Marks a test as belonging to a specific test pyramid level.
class PyramidLevel {
  const PyramidLevel(this.level);
  final String level;
}

/// Marks a test class as testing a specific feature.
class Feature {
  const Feature(this.name);
  final String name;
}
```

### 4.7 `lib/src/builders/given_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the Given phase of a scenario.
///
/// Subclass this to define domain-specific precondition methods.
/// Each method typically returns a [DomainObjectBuilder] for fluent
/// configuration of that domain object.
///
/// Example:
/// ```dart
/// class OrderGivenBuilder extends GivenBuilder {
///   OrderGivenBuilder(super.scenario);
///
///   ProductGivenBuilder product() => ProductGivenBuilder(scenario);
///   CouponGivenBuilder coupon() => CouponGivenBuilder(scenario);
/// }
/// ```
abstract class GivenBuilder {
  /// Create a GivenBuilder wrapping the scenario in [NeedsWhen] state.
  GivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the underlying scenario builder.
  ///
  /// Subclasses and domain object builders use this to register steps.
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
```

### 4.8 `lib/src/builders/when_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the When phase of a scenario.
///
/// Subclass this to define domain-specific action/use-case methods.
/// Each method typically returns a [DomainObjectBuilder] for fluent
/// configuration of that action's parameters.
///
/// Example:
/// ```dart
/// class OrderWhenBuilder extends WhenBuilder {
///   OrderWhenBuilder(super.scenario);
///
///   PlaceOrderWhenBuilder placeOrder() => PlaceOrderWhenBuilder(scenario);
///   CancelOrderWhenBuilder cancelOrder() => CancelOrderWhenBuilder(scenario);
/// }
/// ```
abstract class WhenBuilder {
  /// Create a WhenBuilder wrapping the scenario in [NeedsThen] state.
  WhenBuilder(this._scenario);

  final ScenarioBuilder<NeedsThen> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<NeedsThen> get scenario => _scenario;
}
```

### 4.9 `lib/src/builders/then_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for the Then phase of a scenario.
///
/// Subclass this to define domain-specific assertion methods.
/// Methods that directly assert (like `shouldSucceed()`) register
/// an assertion and return a terminal object. Methods that start
/// a fluent assertion chain (like `order()`) return an
/// [AssertionBuilder] subclass.
///
/// Example:
/// ```dart
/// class OrderThenBuilder extends ThenBuilder {
///   OrderThenBuilder(super.scenario);
///
///   ScenarioBuilder<ReadyToRun> shouldSucceed() {
///     return registerAssertion((ctx) {
///       expect(ctx.get<bool>('success'), isTrue);
///     });
///   }
///
///   OrderAssertionBuilder order() {
///     return OrderAssertionBuilder(scenario);
///   }
/// }
/// ```
abstract class ThenBuilder {
  /// Create a ThenBuilder wrapping the scenario in [ReadyToRun] state.
  ThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ///
  /// Use this helper in subclass methods like `shouldSucceed()`.
  ScenarioBuilder<ReadyToRun> registerAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }
}
```

### 4.10 `lib/src/builders/and_given_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the And phase after Given (additional preconditions).
///
/// Structurally identical to [GivenBuilder]. Feature scenarios typically
/// reuse their GivenBuilder for `.and` after Given, but this base class
/// exists in case different behavior is needed.
abstract class AndGivenBuilder {
  AndGivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
```

### 4.11 `lib/src/builders/and_then_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for the And phase after Then (additional assertions).
///
/// Subclass this to define domain-specific assertion methods
/// available after `.and` in the Then phase.
abstract class AndThenBuilder {
  AndThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ScenarioBuilder<ReadyToRun> registerAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.and,
        action: action,
        description: description,
      ),
    );
  }
}
```

### 4.12 `lib/src/builders/domain_object_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for fluent domain object builders.
///
/// Domain object builders are used in the Given and When phases to
/// configure preconditions and actions with fluent `.withX()` methods.
///
/// The type parameter [TParent] is the phantom type of the scenario
/// state that this builder operates within:
/// - `NeedsWhen` for Given-phase builders
/// - `NeedsThen` for When-phase builders
///
/// ## How it works
///
/// 1. Each `.withX()` method stores a value and returns `this` for chaining.
/// 2. The subclass overrides [applyToContext] to write built values to context.
/// 3. The subclass defines transition getters (`.when`, `.then`, `.and`) that
///    call [finalizeStep], then wrap the next scenario state in the
///    feature-specific builder.
///
/// ## Example (Given phase)
///
/// ```dart
/// class ProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
///   ProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
///       : super(scenario, StepPhase.given);
///
///   double _unitPrice = 0;
///
///   ProductGivenBuilder withUnitPrice(double price) {
///     _unitPrice = price;
///     return this;
///   }
///
///   @override
///   void applyToContext(TestContext ctx) {
///     ctx.set('product_unit_price', _unitPrice);
///   }
///
///   // Transition getter — defined by the subclass, NOT the framework,
///   // because it returns a feature-specific WhenBuilder.
///   OrderWhenBuilder get when {
///     final scenario = finalizeStep();
///     final next = scenario.addStep<NeedsThen>(
///       StepRecord(phase: StepPhase.when, action: (_) {}),
///     );
///     return OrderWhenBuilder(next);
///   }
/// }
/// ```
abstract class DomainObjectBuilder<TParent extends ScenarioState> {
  /// Create a domain object builder.
  ///
  /// [scenario] is the current scenario builder in state [TParent].
  /// [phase] is the step phase (given, when) this builder belongs to.
  DomainObjectBuilder(this._scenario, this._phase);

  final ScenarioBuilder<TParent> _scenario;
  final StepPhase _phase;

  /// Apply this builder's configured values to the test context.
  ///
  /// Subclasses override this to store domain objects or invoke use cases.
  void applyToContext(TestContext ctx);

  /// Finalize this builder: register the configured action as a step
  /// and return the updated scenario builder (same state [TParent]).
  ///
  /// Call this from transition getters (`.when`, `.then`, `.and`)
  /// before transitioning to the next state.
  ScenarioBuilder<TParent> finalizeStep() {
    return _scenario.appendStep(
      StepRecord(
        phase: _phase,
        action: (ctx) => applyToContext(ctx),
      ),
    );
  }
}
```

### 4.13 `lib/src/builders/assertion_builder.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for fluent assertion builders.
///
/// Assertion builders are used in the Then phase to verify outcomes
/// with fluent `.hasX()` methods. Each `.hasX()` method calls
/// [addAssertionStep] to register the assertion AND returns `this`
/// (the concrete subclass) for further chaining.
///
/// The subclass also defines `.and` and `.run()` getters to transition
/// out of the assertion chain.
///
/// ## Example
///
/// ```dart
/// class OrderAssertionBuilder extends AssertionBuilder {
///   OrderAssertionBuilder(super.scenario);
///
///   OrderAssertionBuilder hasBasePrice(double expected) {
///     addAssertionStep((ctx) {
///       final order = ctx.get<Order>('order');
///       expect(order.basePrice, equals(expected));
///     });
///     return this;
///   }
///
///   void run() => currentScenario.run();
/// }
/// ```
abstract class AssertionBuilder {
  /// Create an assertion builder wrapping the scenario in [ReadyToRun] state.
  AssertionBuilder(this._scenario);

  ScenarioBuilder<ReadyToRun> _scenario;

  /// Register an assertion step.
  ///
  /// Call this from `.hasX()` methods. The assertion is recorded as a
  /// step in the scenario.
  void addAssertionStep(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    _scenario = _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }

  /// Get the current scenario builder with all assertions registered.
  ///
  /// Use this in `.and` and `.run()` implementations.
  ScenarioBuilder<ReadyToRun> get currentScenario => _scenario;
}
```

### 4.14 `lib/src/builders/feature_scenario.dart` — NEW

```dart
import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';

/// Abstract base for feature-specific scenario entry points.
///
/// Extend this to create a typed scenario for each feature. It provides
/// the `.given` getter that returns your custom GivenBuilder.
///
/// ## Example
///
/// ```dart
/// class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
///   OrderScenario(super.description);
///
///   @override
///   OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> s) =>
///       OrderGivenBuilder(s);
/// }
/// ```
///
/// Usage:
/// ```dart
/// OrderScenario('should calculate base price')
///   .given.product().withUnitPrice(20.00)
///   .when.placeOrder().withQuantity(5)
///   .then.shouldSucceed()
///   .run();
/// ```
abstract class FeatureScenario<TGiven> {
  /// Create a new feature scenario with the given description.
  FeatureScenario(String description)
      : _builder = ScenarioBuilder.create(description);

  final ScenarioBuilder<NeedsGiven> _builder;

  /// Factory method: create the feature-specific Given builder.
  TGiven createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario);

  /// Transition to the Given phase.
  ///
  /// Returns the feature-specific GivenBuilder with domain methods
  /// available for IDE autocompletion.
  TGiven get given {
    final nextState = _builder.addStep<NeedsWhen>(
      StepRecord(phase: StepPhase.given, action: (_) {}),
    );
    return createGivenBuilder(nextState);
  }
}
```

### 4.15 `lib/src/runner/scenario_runner.dart` — NEW

```dart
import 'package:test/test.dart' as test_pkg;

import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Executes a completed scenario as a `package:test` test case.
class ScenarioRunner {
  const ScenarioRunner._();

  /// Run a scenario as a test.
  ///
  /// Each recorded step's action is executed in order, with async
  /// actions properly awaited.
  static void run(ScenarioBuilder<ReadyToRun> scenario) {
    test_pkg.test(scenario.description, () async {
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
      }
    });
  }

  /// Run a scenario as a test with a channel label prefix.
  ///
  /// The test name becomes `[channelName] description`.
  static void runWithChannel(
    ScenarioBuilder<ReadyToRun> scenario, {
    required String channelName,
  }) {
    test_pkg.test('[$channelName] ${scenario.description}', () async {
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
      }
    });
  }

  /// Run a scenario directly (without registering a test).
  ///
  /// Useful for testing the scenario builder itself.
  static Future<void> execute(ScenarioBuilder<ReadyToRun> scenario) async {
    for (final step in scenario.steps) {
      final result = step.action(scenario.context);
      if (result is Future) {
        await result;
      }
    }
  }
}
```

### 4.16 All channel, driver, fixture, matcher, helper files — KEEP UNCHANGED

The following files are kept exactly as they are:
- `lib/src/channels/channel.dart`
- `lib/src/channels/ui_channel.dart`
- `lib/src/channels/api_channel.dart`
- `lib/src/channels/cli_channel.dart`
- `lib/src/drivers/driver.dart`
- `lib/src/drivers/flutter_widget_driver.dart`
- `lib/src/drivers/http_driver.dart`
- `lib/src/fixtures/fixture_base.dart`
- `lib/src/fixtures/creation_methods.dart`
- `lib/src/fixtures/test_data_builder.dart`
- `lib/src/matchers/valenty_matchers.dart`
- `lib/src/matchers/delta_assertion.dart`
- `lib/src/helpers/parameterized_test.dart`
- `lib/src/helpers/guard_assertion.dart`

---

## 5. Complete Test Spec

### Directory Structure

```
test/
  core/
    phantom_types_test.dart                — KEEP (unchanged, still valid)
    test_context_test.dart                 — KEEP (unchanged, still valid)
    step_record_test.dart                  — NEW (replaces step_test.dart)
    scenario_builder_test.dart             — NEW (replaces scenario_test.dart)
  builders/
    given_builder_test.dart                — NEW
    when_builder_test.dart                 — NEW
    then_builder_test.dart                 — NEW
    domain_object_builder_test.dart        — NEW
    assertion_builder_test.dart            — NEW
    feature_scenario_test.dart             — NEW
  runner/
    scenario_runner_test.dart              — NEW
  integration/
    typed_fluent_dsl_test.dart             — NEW (end-to-end test)
  fixtures/
    test_data_builder_test.dart            — KEEP
  helpers/
    guard_assertion_test.dart              — KEEP
    parameterized_test_test.dart           — KEEP
  matchers/
    valenty_matchers_test.dart             — KEEP
```

### 5.1 `test/core/step_record_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';

void main() {
  group('StepRecord', () {
    test('stores phase and action', () {
      final record = StepRecord(
        phase: StepPhase.given,
        action: (ctx) => ctx.set('key', 'value'),
      );

      expect(record.phase, StepPhase.given);
      expect(record.description, isNull);

      final ctx = TestContext();
      record.action(ctx);
      expect(ctx.get<String>('key'), 'value');
    });

    test('stores optional description', () {
      final record = StepRecord(
        phase: StepPhase.then,
        action: (_) {},
        description: 'should have base price',
      );

      expect(record.description, 'should have base price');
    });

    test('all StepPhase values are accessible', () {
      expect(StepPhase.values, containsAll([
        StepPhase.given,
        StepPhase.when,
        StepPhase.then,
        StepPhase.and,
      ]));
    });
  });
}
```

### 5.2 `test/core/scenario_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';

void main() {
  group('ScenarioBuilder', () {
    test('create returns ScenarioBuilder<NeedsGiven>', () {
      final builder = ScenarioBuilder.create('test scenario');
      expect(builder, isA<ScenarioBuilder<NeedsGiven>>());
      expect(builder.description, 'test scenario');
      expect(builder.steps, isEmpty);
    });

    test('addStep transitions phantom type', () {
      final builder = ScenarioBuilder.create('test');
      final next = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );

      expect(next, isA<ScenarioBuilder<NeedsWhen>>());
      expect(next.steps.length, 1);
      expect(next.steps.first.phase, StepPhase.given);
    });

    test('appendStep keeps same phantom type', () {
      final builder = ScenarioBuilder.create('test');
      final inWhen = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final withExtra = inWhen.appendStep(
        StepRecord(phase: StepPhase.and, action: (_) {}),
      );

      expect(withExtra, isA<ScenarioBuilder<NeedsWhen>>());
      expect(withExtra.steps.length, 2);
    });

    test('context is shared across state transitions', () {
      final builder = ScenarioBuilder.create('test');
      final next = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );

      builder.context.set('shared', 42);
      expect(next.context.get<int>('shared'), 42);
    });

    test('steps list is immutable', () {
      final builder = ScenarioBuilder.create('test');
      expect(
        () => builder.steps.add(
          StepRecord(phase: StepPhase.given, action: (_) {}),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('full chain NeedsGiven -> NeedsWhen -> NeedsThen -> ReadyToRun', () {
      final s0 = ScenarioBuilder.create('test');
      expect(s0, isA<ScenarioBuilder<NeedsGiven>>());

      final s1 = s0.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      expect(s1, isA<ScenarioBuilder<NeedsWhen>>());

      final s2 = s1.addStep<NeedsThen>(
        StepRecord(phase: StepPhase.when, action: (_) {}),
      );
      expect(s2, isA<ScenarioBuilder<NeedsThen>>());

      final s3 = s2.addStep<ReadyToRun>(
        StepRecord(phase: StepPhase.then, action: (_) {}),
      );
      expect(s3, isA<ScenarioBuilder<ReadyToRun>>());
      expect(s3.steps.length, 3);
    });
  });
}
```

### 5.3 `test/builders/domain_object_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';
import 'package:valenty_dsl/src/builders/domain_object_builder.dart';

/// Concrete test implementation of DomainObjectBuilder.
class _TestDomainBuilder extends DomainObjectBuilder<NeedsWhen> {
  _TestDomainBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _value = 'default';

  _TestDomainBuilder withValue(String value) {
    _value = value;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('test_value', _value);
  }
}

void main() {
  group('DomainObjectBuilder', () {
    late ScenarioBuilder<NeedsWhen> scenario;

    setUp(() {
      scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
    });

    test('withX methods return same builder for chaining', () {
      final builder = _TestDomainBuilder(scenario);
      final result = builder.withValue('hello');
      expect(identical(result, builder), isTrue);
    });

    test('finalizeStep registers a step and returns scenario', () {
      final builder = _TestDomainBuilder(scenario);
      builder.withValue('hello');

      final finalized = builder.finalizeStep();
      expect(finalized, isA<ScenarioBuilder<NeedsWhen>>());
      // Original scenario had 1 step; finalized has 2
      expect(finalized.steps.length, scenario.steps.length + 1);
    });

    test('applyToContext stores values in context when step executes', () {
      final builder = _TestDomainBuilder(scenario);
      builder.withValue('hello');

      final finalized = builder.finalizeStep();
      final lastStep = finalized.steps.last;

      // Execute the step action
      final ctx = TestContext();
      lastStep.action(ctx);
      expect(ctx.get<String>('test_value'), 'hello');
    });

    test('default values are applied when no withX is called', () {
      final builder = _TestDomainBuilder(scenario);
      final finalized = builder.finalizeStep();
      final lastStep = finalized.steps.last;

      final ctx = TestContext();
      lastStep.action(ctx);
      expect(ctx.get<String>('test_value'), 'default');
    });
  });
}
```

### 5.4 `test/builders/assertion_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';
import 'package:valenty_dsl/src/builders/assertion_builder.dart';

class _TestAssertionBuilder extends AssertionBuilder {
  _TestAssertionBuilder(super.scenario);

  _TestAssertionBuilder hasValue(String expected) {
    addAssertionStep((ctx) {
      final actual = ctx.get<String>('value');
      expect(actual, equals(expected));
    }, description: 'has value $expected');
    return this;
  }
}

void main() {
  group('AssertionBuilder', () {
    late ScenarioBuilder<ReadyToRun> readyScenario;

    setUp(() {
      readyScenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          )
          .addStep<ReadyToRun>(
            StepRecord(phase: StepPhase.then, action: (_) {}),
          );
    });

    test('hasX methods return same builder for chaining', () {
      final builder = _TestAssertionBuilder(readyScenario);
      final result = builder.hasValue('test');
      expect(identical(result, builder), isTrue);
    });

    test('addAssertionStep registers step in scenario', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('test');

      final current = builder.currentScenario;
      expect(current.steps.length, readyScenario.steps.length + 1);
    });

    test('multiple hasX calls register multiple steps', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('a').hasValue('b');

      final current = builder.currentScenario;
      expect(current.steps.length, readyScenario.steps.length + 2);
    });

    test('registered assertion executes correctly', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('hello');

      final current = builder.currentScenario;
      final lastStep = current.steps.last;

      final ctx = TestContext();
      ctx.set('value', 'hello');
      // Should not throw
      lastStep.action(ctx);
    });
  });
}
```

### 5.5 `test/builders/given_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/builders/given_builder.dart';

class _TestGivenBuilder extends GivenBuilder {
  _TestGivenBuilder(super.scenario);

  bool productCalled = false;

  _TestGivenBuilder product() {
    productCalled = true;
    return this;
  }
}

void main() {
  group('GivenBuilder', () {
    test('stores scenario in NeedsWhen state', () {
      final scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final builder = _TestGivenBuilder(scenario);
      expect(builder.scenario, isA<ScenarioBuilder<NeedsWhen>>());
    });

    test('subclass can define domain methods', () {
      final scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final builder = _TestGivenBuilder(scenario);
      builder.product();
      expect(builder.productCalled, isTrue);
    });
  });
}
```

### 5.6 `test/builders/when_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/builders/when_builder.dart';

class _TestWhenBuilder extends WhenBuilder {
  _TestWhenBuilder(super.scenario);

  bool placeOrderCalled = false;

  _TestWhenBuilder placeOrder() {
    placeOrderCalled = true;
    return this;
  }
}

void main() {
  group('WhenBuilder', () {
    test('stores scenario in NeedsThen state', () {
      final scenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          );
      final builder = _TestWhenBuilder(scenario);
      expect(builder.scenario, isA<ScenarioBuilder<NeedsThen>>());
    });

    test('subclass can define use case methods', () {
      final scenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          );
      final builder = _TestWhenBuilder(scenario);
      builder.placeOrder();
      expect(builder.placeOrderCalled, isTrue);
    });
  });
}
```

### 5.7 `test/builders/then_builder_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';
import 'package:valenty_dsl/src/builders/then_builder.dart';

class _TestThenBuilder extends ThenBuilder {
  _TestThenBuilder(super.scenario);

  ScenarioBuilder<ReadyToRun> shouldSucceed() {
    return registerAssertion((ctx) {
      expect(ctx.get<bool>('success'), isTrue);
    }, description: 'should succeed');
  }
}

void main() {
  group('ThenBuilder', () {
    late ScenarioBuilder<ReadyToRun> readyScenario;

    setUp(() {
      readyScenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          )
          .addStep<ReadyToRun>(
            StepRecord(phase: StepPhase.then, action: (_) {}),
          );
    });

    test('stores scenario in ReadyToRun state', () {
      final builder = _TestThenBuilder(readyScenario);
      expect(builder.scenario, isA<ScenarioBuilder<ReadyToRun>>());
    });

    test('registerAssertion adds step and returns ReadyToRun', () {
      final builder = _TestThenBuilder(readyScenario);
      final result = builder.shouldSucceed();

      expect(result, isA<ScenarioBuilder<ReadyToRun>>());
      expect(result.steps.length, readyScenario.steps.length + 1);
    });

    test('registered assertion executes correctly', () {
      final builder = _TestThenBuilder(readyScenario);
      final result = builder.shouldSucceed();

      final lastStep = result.steps.last;
      final ctx = TestContext();
      ctx.set('success', true);
      // Should not throw
      lastStep.action(ctx);
    });
  });
}
```

### 5.8 `test/builders/feature_scenario_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/builders/feature_scenario.dart';
import 'package:valenty_dsl/src/builders/given_builder.dart';

class _SimpleGivenBuilder extends GivenBuilder {
  _SimpleGivenBuilder(super.scenario);

  bool domainMethodCalled = false;

  _SimpleGivenBuilder domainMethod() {
    domainMethodCalled = true;
    return this;
  }
}

class _SimpleScenario extends FeatureScenario<_SimpleGivenBuilder> {
  _SimpleScenario(super.description);

  @override
  _SimpleGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return _SimpleGivenBuilder(scenario);
  }
}

void main() {
  group('FeatureScenario', () {
    test('given returns the feature-specific GivenBuilder', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      expect(given, isA<_SimpleGivenBuilder>());
    });

    test('GivenBuilder has domain methods available', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      given.domainMethod();
      expect(given.domainMethodCalled, isTrue);
    });

    test('GivenBuilder scenario is in NeedsWhen state', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      expect(given.scenario, isA<ScenarioBuilder<NeedsWhen>>());
    });
  });
}
```

### 5.9 `test/runner/scenario_runner_test.dart` — NEW

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/runner/scenario_runner.dart';

void main() {
  group('ScenarioRunner', () {
    test('execute runs all steps in order', () async {
      final executionOrder = <int>[];

      final scenario = ScenarioBuilder.create('execution order test')
          .addStep<NeedsWhen>(StepRecord(
            phase: StepPhase.given,
            action: (_) => executionOrder.add(1),
          ))
          .addStep<NeedsThen>(StepRecord(
            phase: StepPhase.when,
            action: (_) => executionOrder.add(2),
          ))
          .addStep<ReadyToRun>(StepRecord(
            phase: StepPhase.then,
            action: (_) => executionOrder.add(3),
          ));

      await ScenarioRunner.execute(scenario);
      expect(executionOrder, [1, 2, 3]);
    });

    test('execute handles async steps', () async {
      final executionOrder = <int>[];

      final scenario = ScenarioBuilder.create('async test')
          .addStep<NeedsWhen>(StepRecord(
            phase: StepPhase.given,
            action: (_) async {
              await Future<void>.delayed(Duration(milliseconds: 1));
              executionOrder.add(1);
            },
          ))
          .addStep<NeedsThen>(StepRecord(
            phase: StepPhase.when,
            action: (_) async {
              await Future<void>.delayed(Duration(milliseconds: 1));
              executionOrder.add(2);
            },
          ))
          .addStep<ReadyToRun>(StepRecord(
            phase: StepPhase.then,
            action: (_) => executionOrder.add(3),
          ));

      await ScenarioRunner.execute(scenario);
      expect(executionOrder, [1, 2, 3]);
    });

    test('execute passes shared context between steps', () async {
      final scenario = ScenarioBuilder.create('context test')
          .addStep<NeedsWhen>(StepRecord(
            phase: StepPhase.given,
            action: (ctx) => ctx.set('value', 42),
          ))
          .addStep<NeedsThen>(StepRecord(
            phase: StepPhase.when,
            action: (ctx) {
              final v = ctx.get<int>('value');
              ctx.set('doubled', v * 2);
            },
          ))
          .addStep<ReadyToRun>(StepRecord(
            phase: StepPhase.then,
            action: (ctx) {
              expect(ctx.get<int>('doubled'), 84);
            },
          ));

      await ScenarioRunner.execute(scenario);
    });
  });
}
```

### 5.10 `test/integration/typed_fluent_dsl_test.dart` — NEW

This is the end-to-end integration test using a complete example with generated-style builders. It demonstrates the full typed fluent DSL working end-to-end.

```dart
import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';
import 'package:valenty_dsl/src/builders/given_builder.dart';
import 'package:valenty_dsl/src/builders/when_builder.dart';
import 'package:valenty_dsl/src/builders/then_builder.dart';
import 'package:valenty_dsl/src/builders/and_then_builder.dart';
import 'package:valenty_dsl/src/builders/domain_object_builder.dart';
import 'package:valenty_dsl/src/builders/assertion_builder.dart';
import 'package:valenty_dsl/src/builders/feature_scenario.dart';
import 'package:valenty_dsl/src/runner/scenario_runner.dart';

// ── Domain model (would be in user's project) ──

class Product {
  Product({required this.name, required this.unitPrice});
  final String name;
  final double unitPrice;
}

class Order {
  Order({required this.quantity, required this.basePrice, required this.success});
  final int quantity;
  final double basePrice;
  final bool success;
}

// ── Generated builders (would be scaffolded by CLI) ──

class TestOrderScenario extends FeatureScenario<TestOrderGivenBuilder> {
  TestOrderScenario(super.description);

  @override
  TestOrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return TestOrderGivenBuilder(scenario);
  }
}

class TestOrderGivenBuilder extends GivenBuilder {
  TestOrderGivenBuilder(super.scenario);

  TestProductGivenBuilder product() {
    return TestProductGivenBuilder(scenario);
  }
}

class TestProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  TestProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'Default Product';
  double _unitPrice = 0;

  TestProductGivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  TestProductGivenBuilder withUnitPrice(double price) {
    _unitPrice = price;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
  }

  TestOrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return TestOrderWhenBuilder(next);
  }

  TestOrderGivenBuilder get and {
    final finalized = finalizeStep();
    return TestOrderGivenBuilder(finalized);
  }
}

class TestOrderWhenBuilder extends WhenBuilder {
  TestOrderWhenBuilder(super.scenario);

  TestPlaceOrderBuilder placeOrder() {
    return TestPlaceOrderBuilder(scenario);
  }
}

class TestPlaceOrderBuilder extends DomainObjectBuilder<NeedsThen> {
  TestPlaceOrderBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  TestPlaceOrderBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final product = ctx.get<Product>('product');
    final basePrice = product.unitPrice * _quantity;
    ctx.set('order', Order(
      quantity: _quantity,
      basePrice: basePrice,
      success: true,
    ));
  }

  TestOrderThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return TestOrderThenBuilder(next);
  }
}

class TestOrderThenBuilder extends ThenBuilder {
  TestOrderThenBuilder(super.scenario);

  _TestOrderThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isTrue);
    }, description: 'should succeed');
    return _TestOrderThenTerminal(next);
  }

  TestOrderAssertionBuilder order() {
    return TestOrderAssertionBuilder(scenario);
  }
}

class _TestOrderThenTerminal {
  _TestOrderThenTerminal(this._scenario);
  final ScenarioBuilder<ReadyToRun> _scenario;

  TestOrderAndThenBuilder get and => TestOrderAndThenBuilder(_scenario);
  void run() => ScenarioRunner.run(_scenario);
}

class TestOrderAndThenBuilder extends AndThenBuilder {
  TestOrderAndThenBuilder(super.scenario);

  TestOrderAssertionBuilder order() {
    return TestOrderAssertionBuilder(scenario);
  }
}

class TestOrderAssertionBuilder extends AssertionBuilder {
  TestOrderAssertionBuilder(super.scenario);

  TestOrderAssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.basePrice, equals(expected));
    });
    return this;
  }

  TestOrderAssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.quantity, equals(expected));
    });
    return this;
  }

  TestOrderAndThenBuilder get and => TestOrderAndThenBuilder(currentScenario);
  void run() => ScenarioRunner.run(currentScenario);
}

// ── Tests ──

void main() {
  group('Typed Fluent DSL Integration', () {
    test('full chain: given.product().withX().when.placeOrder().withX().then.shouldSucceed()',
        () async {
      // Build the scenario using typed fluent DSL
      final scenarioBuilder = TestOrderScenario('should calculate base price')
          .given.product()
              .withName('Widget')
              .withUnitPrice(20.00)
          .when.placeOrder()
              .withQuantity(5)
          .then.shouldSucceed();

      // Execute directly (without registering a test) for validation
      await ScenarioRunner.execute(scenarioBuilder._scenario);
    });

    test('full chain with assertion builder: .then.order().hasBasePrice()',
        () async {
      final assertionBuilder = TestOrderScenario('should have correct base price')
          .given.product()
              .withUnitPrice(20.00)
          .when.placeOrder()
              .withQuantity(5)
          .then.order()
              .hasBasePrice(100.00)
              .hasQuantity(5);

      await ScenarioRunner.execute(assertionBuilder.currentScenario);
    });

    test('chain with .and for additional assertions', () async {
      final terminal = TestOrderScenario('should succeed and have correct price')
          .given.product()
              .withUnitPrice(20.00)
          .when.placeOrder()
              .withQuantity(5)
          .then.shouldSucceed();

      final assertionBuilder = terminal.and.order()
          .hasBasePrice(100.00)
          .hasQuantity(5);

      await ScenarioRunner.execute(assertionBuilder.currentScenario);
    });

    test('context flows from given through when to then', () async {
      final scenario = ScenarioBuilder.create('context flow test')
          .addStep<NeedsWhen>(StepRecord(
            phase: StepPhase.given,
            action: (ctx) => ctx.set('product',
                Product(name: 'Test', unitPrice: 10.00)),
          ))
          .addStep<NeedsThen>(StepRecord(
            phase: StepPhase.when,
            action: (ctx) {
              final product = ctx.get<Product>('product');
              ctx.set('order', Order(
                quantity: 3,
                basePrice: product.unitPrice * 3,
                success: true,
              ));
            },
          ))
          .addStep<ReadyToRun>(StepRecord(
            phase: StepPhase.then,
            action: (ctx) {
              final order = ctx.get<Order>('order');
              expect(order.basePrice, 30.00);
            },
          ));

      await ScenarioRunner.execute(scenario);
    });

    // COMPILE-TIME SAFETY DOCUMENTATION:
    // The following lines would NOT compile, demonstrating type safety:
    //
    // 1. Cannot call .when before .given:
    //    TestOrderScenario('bad').when  // ERROR: no 'when' on FeatureScenario
    //
    // 2. Cannot call .then before .when:
    //    TestOrderScenario('bad').given.product().then  // ERROR: no 'then' on ProductGivenBuilder
    //
    // 3. Cannot call .run() before .then:
    //    TestOrderScenario('bad').given.product().withUnitPrice(20).run()
    //    // ERROR: no 'run' on ProductGivenBuilder
    //
    // 4. IDE shows only valid methods at each point:
    //    After .given  → product(), coupon()         (domain objects)
    //    After .withX  → .withY(), .when, .and       (more config or transition)
    //    After .when   → placeOrder(), cancelOrder() (use cases)
    //    After .then   → shouldSucceed(), order()    (assertions)
    //    After .hasX   → .hasY(), .and, .run()       (more assertions or finish)
  });
}
```

---

## 6. Example Usage

This section shows what a user's test file looks like after scaffolding an "Order" feature.

### 6.1 User's Test File

```dart
// test/acceptance/order_test.dart
import 'package:test/test.dart';
import 'package:my_app/test_dsl/order/order_scenario.dart';

@Feature('Order Management')
@Channel({ChannelType.ui, ChannelType.api})
void main() {
  group('Order Pricing', () {
    // Test 1: Simple base price calculation
    OrderScenario('should calculate base price for single product')
      .given.product()
          .withName('Premium Widget')
          .withUnitPrice(20.00)
      .when.placeOrder()
          .withQuantity(5)
      .then.shouldSucceed()
      .and.order()
          .hasBasePrice(100.00)
      .run();

    // Test 2: Order with coupon
    OrderScenario('should apply coupon discount')
      .given.product()
          .withUnitPrice(50.00)
      .and.coupon()
          .withCode('SAVE10')
          .withDiscountPercent(10)
      .when.placeOrder()
          .withQuantity(2)
      .then.shouldSucceed()
      .and.order()
          .hasBasePrice(90.00)
      .run();

    // Test 3: Multiple assertions
    OrderScenario('should have correct order details')
      .given.product()
          .withUnitPrice(25.00)
      .when.placeOrder()
          .withQuantity(4)
      .then.order()
          .hasBasePrice(100.00)
          .hasQuantity(4)
      .run();
  });
}
```

### 6.2 What Does NOT Compile (and Why)

```dart
// ERROR 1: Cannot skip Given
OrderScenario('bad')
  .when  // COMPILE ERROR: FeatureScenario has no 'when' getter
  .placeOrder();

// ERROR 2: Cannot go from Given to Then (skipping When)
OrderScenario('bad')
  .given.product()
  .then  // COMPILE ERROR: ProductGivenBuilder has no 'then' getter
  .shouldSucceed();

// ERROR 3: Cannot call run before Then
OrderScenario('bad')
  .given.product().withUnitPrice(20)
  .when.placeOrder()
  .run()  // COMPILE ERROR: PlaceOrderWhenBuilder has no 'run' method

// ERROR 4: Cannot call domain methods from wrong phase
OrderScenario('bad')
  .given.placeOrder()  // COMPILE ERROR: OrderGivenBuilder has no 'placeOrder'

// ERROR 5: Cannot call withQuantity on product
OrderScenario('bad')
  .given.product()
  .withQuantity(5)  // COMPILE ERROR: ProductGivenBuilder has no 'withQuantity'

// ERROR 6: Cannot call hasBasePrice in Given phase
OrderScenario('bad')
  .given.product()
  .hasBasePrice(100)  // COMPILE ERROR: ProductGivenBuilder has no 'hasBasePrice'
```

### 6.3 Multi-Channel Testing Example

```dart
// test/acceptance/order_multi_channel_test.dart
import 'package:test/test.dart';
import 'package:my_app/test_dsl/order/order_scenario.dart';

void main() {
  for (final channel in [ChannelType.ui, ChannelType.api]) {
    group('Order via ${channel.name}', () {
      OrderScenario('should calculate base price')
        .given.product()
            .withUnitPrice(20.00)
        .when.placeOrder()
            .withQuantity(5)
        .then.shouldSucceed()
        .and.order()
            .hasBasePrice(100.00)
        .runWithChannel(channel.name);
    });
  }
}
```

---

## 7. Migration Notes

### 7.1 Files to DELETE

These files are replaced by the new architecture:

| Old File | Reason |
|----------|--------|
| `lib/src/core/step.dart` | Replaced by `lib/src/core/step_record.dart` |
| `lib/src/core/scenario.dart` | Replaced by `lib/src/core/scenario_builder.dart` |
| `test/core/step_test.dart` | Replaced by `test/core/step_record_test.dart` |
| `test/core/scenario_test.dart` | Replaced by `test/core/scenario_builder_test.dart` |

### 7.2 Files to REWRITE

| File | What Changes |
|------|-------------|
| `lib/src/core/scenario_extensions.dart` | Completely rewritten — only provides `.run()` and `.runWithChannel()` on `ScenarioBuilder<ReadyToRun>` |
| `lib/src/core/annotations.dart` | `Channel` now takes `Set<ChannelType>` instead of `String`; added `ChannelType` enum |

### 7.3 Files to CREATE (new)

| File | Purpose |
|------|---------|
| `lib/src/core/step_record.dart` | New step recording without string descriptions |
| `lib/src/core/scenario_builder.dart` | New core builder with phantom types |
| `lib/src/builders/given_builder.dart` | Base class for Given phase |
| `lib/src/builders/when_builder.dart` | Base class for When phase |
| `lib/src/builders/then_builder.dart` | Base class for Then phase |
| `lib/src/builders/and_given_builder.dart` | Base for And after Given |
| `lib/src/builders/and_then_builder.dart` | Base for And after Then |
| `lib/src/builders/domain_object_builder.dart` | Base for fluent domain object builders |
| `lib/src/builders/assertion_builder.dart` | Base for fluent assertion builders |
| `lib/src/builders/feature_scenario.dart` | Abstract base for feature scenarios |
| `lib/src/runner/scenario_runner.dart` | Test execution engine |

### 7.4 Files to KEEP (unchanged)

All channel, driver, fixture, matcher, and helper files remain unchanged:

- `lib/src/channels/channel.dart`
- `lib/src/channels/ui_channel.dart`
- `lib/src/channels/api_channel.dart`
- `lib/src/channels/cli_channel.dart`
- `lib/src/drivers/driver.dart`
- `lib/src/drivers/flutter_widget_driver.dart`
- `lib/src/drivers/http_driver.dart`
- `lib/src/fixtures/fixture_base.dart`
- `lib/src/fixtures/creation_methods.dart`
- `lib/src/fixtures/test_data_builder.dart`
- `lib/src/matchers/valenty_matchers.dart`
- `lib/src/matchers/delta_assertion.dart`
- `lib/src/helpers/parameterized_test.dart`
- `lib/src/helpers/guard_assertion.dart`
- `lib/src/core/phantom_types.dart`
- `lib/src/core/test_context.dart`

Tests to keep:
- `test/core/test_context_test.dart`
- `test/fixtures/test_data_builder_test.dart`
- `test/helpers/guard_assertion_test.dart`
- `test/helpers/parameterized_test_test.dart`
- `test/matchers/valenty_matchers_test.dart`

### 7.5 pubspec.yaml Changes

No changes needed. The existing dependencies (`meta: ^1.12.0`, `test: ^1.25.0`) are sufficient.

---

## 8. Barrel Export

### Updated `lib/valenty_dsl.dart`

```dart
/// Compile-time safe typed fluent builder DSL for Dart/Flutter testing
/// with phantom types.
library;

// Core
export 'src/core/annotations.dart';
export 'src/core/phantom_types.dart';
export 'src/core/scenario_builder.dart';
export 'src/core/scenario_extensions.dart';
export 'src/core/step_record.dart';
export 'src/core/test_context.dart';

// Builders
export 'src/builders/and_given_builder.dart';
export 'src/builders/and_then_builder.dart';
export 'src/builders/assertion_builder.dart';
export 'src/builders/domain_object_builder.dart';
export 'src/builders/feature_scenario.dart';
export 'src/builders/given_builder.dart';
export 'src/builders/then_builder.dart';
export 'src/builders/when_builder.dart';

// Runner
export 'src/runner/scenario_runner.dart';

// Channels
export 'src/channels/channel.dart';
export 'src/channels/ui_channel.dart';
export 'src/channels/api_channel.dart';
export 'src/channels/cli_channel.dart';

// Drivers
export 'src/drivers/driver.dart';
export 'src/drivers/flutter_widget_driver.dart';
export 'src/drivers/http_driver.dart';

// Fixtures
export 'src/fixtures/fixture_base.dart';
export 'src/fixtures/creation_methods.dart';
export 'src/fixtures/test_data_builder.dart';

// Matchers
export 'src/matchers/valenty_matchers.dart';
export 'src/matchers/delta_assertion.dart';

// Helpers
export 'src/helpers/parameterized_test.dart';
export 'src/helpers/guard_assertion.dart';
```

---

## Appendix A: Quick Reference — Builder Chain Flow

```
┌──────────────────────┐
│   FeatureScenario    │  OrderScenario('description')
│   .given (getter)    │──→ Returns OrderGivenBuilder
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│   GivenBuilder       │  .product() / .coupon()
│   domain methods     │──→ Returns DomainObjectBuilder<NeedsWhen>
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│ DomainObjectBuilder  │  .withUnitPrice() / .withName()
│ <NeedsWhen>          │──→ Returns self (fluent chaining)
│   .when (getter)     │──→ finalizeStep() → addStep<NeedsThen> → WhenBuilder
│   .and  (getter)     │──→ finalizeStep() → GivenBuilder (more preconditions)
└──────────────────────┘
           │ (.when)
           ▼
┌──────────────────────┐
│   WhenBuilder        │  .placeOrder() / .cancelOrder()
│   use case methods   │──→ Returns DomainObjectBuilder<NeedsThen>
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│ DomainObjectBuilder  │  .withQuantity()
│ <NeedsThen>          │──→ Returns self (fluent chaining)
│   .then (getter)     │──→ finalizeStep() → addStep<ReadyToRun> → ThenBuilder
└──────────────────────┘
           │ (.then)
           ▼
┌──────────────────────┐
│   ThenBuilder        │  .shouldSucceed() → Terminal (has .and, .run)
│   assertion methods  │  .order() → AssertionBuilder
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  AssertionBuilder    │  .hasBasePrice() / .hasQuantity()
│  fluent assertions   │──→ Returns self (fluent chaining)
│   .and (getter)      │──→ AndThenBuilder (more assertions)
│   .run()             │──→ ScenarioRunner.run()
└──────────────────────┘
           │ (.and)
           ▼
┌──────────────────────┐
│  AndThenBuilder      │  .order() → AssertionBuilder
│  more assertions     │  .shouldSucceed() → Terminal
└──────────────────────┘
```

## Appendix B: Naming Conventions for Scaffolded Files

When the CLI scaffolds a feature named `<Feature>`, it generates:

| Class | Pattern | Example |
|-------|---------|---------|
| Entry point | `<Feature>Scenario` | `OrderScenario` |
| Given builder | `<Feature>GivenBuilder` | `OrderGivenBuilder` |
| When builder | `<Feature>WhenBuilder` | `OrderWhenBuilder` |
| Then builder | `<Feature>ThenBuilder` | `OrderThenBuilder` |
| And-then builder | `<Feature>AndThenBuilder` | `OrderAndThenBuilder` |
| Domain object (Given) | `<Object>GivenBuilder` | `ProductGivenBuilder` |
| Domain action (When) | `<Action>WhenBuilder` | `PlaceOrderWhenBuilder` |
| Assertion builder | `<Object>AssertionBuilder` | `OrderAssertionBuilder` |
| Then terminal | `_<Feature>ThenTerminal` | `_OrderThenTerminal` |

## Appendix C: Implementation Order

The implementation agent should follow this order:

1. **Create** `lib/src/core/step_record.dart`
2. **Create** `lib/src/core/scenario_builder.dart`
3. **Rewrite** `lib/src/core/scenario_extensions.dart`
4. **Rewrite** `lib/src/core/annotations.dart`
5. **Create** `lib/src/runner/scenario_runner.dart`
6. **Create** `lib/src/builders/given_builder.dart`
7. **Create** `lib/src/builders/when_builder.dart`
8. **Create** `lib/src/builders/then_builder.dart`
9. **Create** `lib/src/builders/and_given_builder.dart`
10. **Create** `lib/src/builders/and_then_builder.dart`
11. **Create** `lib/src/builders/domain_object_builder.dart`
12. **Create** `lib/src/builders/assertion_builder.dart`
13. **Create** `lib/src/builders/feature_scenario.dart`
14. **Delete** `lib/src/core/step.dart`
15. **Delete** `lib/src/core/scenario.dart`
16. **Update** `lib/valenty_dsl.dart` (barrel export)
17. **Delete** `test/core/step_test.dart`
18. **Delete** `test/core/scenario_test.dart`
19. **Create** all new test files
20. **Run** `dart test` to verify everything passes
