# Valenty Component Test Architecture

Design document for component-level testing in the Valenty framework, based on
Valentina Jemuovic's Modern Test Pyramid methodology (Optivem Journal).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Fake Generation (AI-first)](#3-fake-generation-ai-first)
4. [Supported External System Types](#4-supported-external-system-types)
5. [Phantom Type Extension](#5-phantom-type-extension)
6. [File Structure for Component Tests](#6-file-structure-for-component-tests)
7. [Test Last Workflow (Legacy Code)](#7-test-last-workflow-legacy-code)
8. [Contract Tests (Future)](#8-contract-tests-future)
9. [Backward Compatibility](#9-backward-compatibility)
10. [Implementation Roadmap](#10-implementation-roadmap)

---

## 1. Overview

### Modern Test Pyramid

The Modern Test Pyramid (Valentina Jemuovic, Optivem Journal) replaces the
classical unit/integration/E2E split with three levels aligned to architectural
boundaries:

```
                    +-------------------+
                    |   System Tests    |   Full stack, deployed environment
                    +-------------------+
                   /                     \
          +---------------------------+
          |     Component Tests       |   Frontend OR Backend in isolation
          +---------------------------+
         /                             \
    +-------------------------------------+
    |          Unit Tests                 |   Pure logic, no I/O
    +-------------------------------------+
```

**System tests** exercise the entire deployed system end-to-end.
**Component tests** exercise one deployable unit (frontend or backend) in
isolation, replacing all external dependencies with fakes.
**Unit tests** exercise pure domain logic with no I/O whatsoever.

### Where Component Tests Fit

Component tests validate that a feature works correctly when its domain logic
interacts with ports (abstract interfaces) -- but without real infrastructure.
Every driven port (repository, external service, platform API) is replaced by
a fake that the test controls.

```
+------------------------------------------------------------------+
|                      Component Test Boundary                     |
|                                                                  |
|  [Test]  -->  [Use Case]  -->  [Port Interface]  -->  [Fake]     |
|                                                                  |
|  The real adapter (Dio, Firebase, SQLite) is NOT present.        |
+------------------------------------------------------------------+
```

### Why Infrastructure Setup Is Separate from Scenarios

Valenty enforces a strict separation between **infrastructure configuration**
(what fakes exist and how they behave) and **scenario specification** (what
business behavior is under test). This separation exists for three reasons:

1. **Reusability.** Multiple scenarios often share the same infrastructure
   setup (same fakes, same stub responses). Extracting setup into a reusable
   `TestEnvironment` eliminates duplication.

2. **Readability.** The scenario chain reads like a business specification --
   Given/When/Then with domain language only. Infrastructure details (stub
   responses, fake wiring) do not pollute the scenario.

3. **Compile-time safety.** The `FeatureSetup` builder produces a typed
   `TestEnvironment` that the scenario accepts. If the environment is
   misconfigured, the error surfaces at build time, not at runtime.

---

## 2. Architecture

### Core Classes

```
FeatureSetup                    FakeBuilder<T>
+-----------------------+       +--------------------------+
| fake(instance)        |------>| whenCalled(method)       |
| build() -> TestEnv    |       | returns(value)           |
+-----------------------+       | succeeds()               |
        |                       | fails(error)             |
        | builds                | and -> FeatureSetup      |
        v                       +--------------------------+
TestEnvironment
+-----------------------+
| fakes: Map<Type, obj> |
| get<T>() -> T         |
+-----------------------+
        |
        | passed to
        v
FeatureScenario
+-----------------------+
| given / when / then   |
| env: TestEnvironment  |
+-----------------------+
```

### FeatureSetup -- Fluent Builder for Infrastructure

`FeatureSetup` is the entry point for configuring all fakes before a scenario
runs. It uses a fluent API with method chaining:

```dart
final env = FeatureSetup()
    .fake(countryService)
        .whenCalled('getTaxRate')
        .returns(0.08)
    .and
    .fake(orderRepository)
        .whenCalled('save')
        .succeeds()
    .build();
```

The `.and` accessor returns to the `FeatureSetup` so additional fakes can be
chained. The `.build()` method produces an immutable `TestEnvironment`.

### FakeBuilder<T> -- Per-Fake Configuration

Each `.fake(instance)` call returns a `FakeBuilder<T>` bound to the fake
object. The builder exposes:

| Method                    | Purpose                                       |
|---------------------------|-----------------------------------------------|
| `whenCalled(String name)` | Selects which method to stub                  |
| `returns(value)`          | Configures a successful return value           |
| `succeeds()`              | Shorthand for `returns(null)` on void methods  |
| `fails(error)`            | Configures the method to throw                 |
| `returnsInOrder(list)`    | Returns values sequentially per call           |
| `and`                     | Returns to parent `FeatureSetup`               |

### TestEnvironment -- The Built Result

`TestEnvironment` is an immutable container holding all configured fakes. It
is passed to `FeatureScenario` at construction time. During step execution,
builders can retrieve fakes from the environment to wire them into the use
case under test.

```dart
class TestEnvironment {
  final Map<Type, Object> _fakes;

  const TestEnvironment(this._fakes);

  /// Retrieve a fake by its port type.
  T get<T>() {
    final fake = _fakes[T];
    if (fake == null) {
      throw StateError('No fake registered for $T');
    }
    return fake as T;
  }

  /// Check if a fake is registered.
  bool has<T>() => _fakes.containsKey(T);
}
```

### Integration with ScenarioBuilder and TestContext

The `TestEnvironment` is stored in the existing `TestContext` under a reserved
key. This means the scenario builder and step records do not need structural
changes -- the environment is simply another value in the context map:

```dart
class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
  OrderScenario(String description, [TestEnvironment? env])
      : _env = env,
        super(description);

  final TestEnvironment? _env;

  @override
  OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    if (_env != null) {
      scenario.context.set('__env__', _env);
    }
    return OrderGivenBuilder(scenario);
  }
}
```

Within any step builder, the environment is accessible via context:

```dart
final repo = scenario.context.get<TestEnvironment>('__env__').get<OrderRepository>();
```

---

## 3. Fake Generation (AI-first)

### The Problem

Dart has no runtime reflection. Frameworks like Mockito for Dart rely on code
generation (`build_runner`), which adds complexity, slows iteration, and
produces opaque generated files.

### The Solution: AI as the Reflection Engine

Valenty takes an AI-first approach: the AI reads port interfaces (abstract
classes) in the developer's codebase and generates manual fake implementations.
No reflection, no code generation, no build_runner.

### Generation Flow

```
Developer's code                AI reads and generates
+---------------------------+   +----------------------------------+
| abstract class OrderRepo  |   | class FakeOrderRepo              |
|   Future<Order> get(id);  |-->|   implements OrderRepo {         |
|   Future<void> save(o);   |   |   // stub storage + setup methods|
| }                         |   | }                                |
+---------------------------+   +----------------------------------+
```

### What the AI Generates

Given a port interface:

```dart
abstract class OrderRepository {
  Future<Order> getOrder(String id);
  Future<void> saveOrder(Order order);
}
```

The AI generates a fake implementing every method with controllable behavior:

```dart
class FakeOrderRepository implements OrderRepository {
  // --- Stub storage for getOrder ---
  final Map<String, Order> _getOrderResults = {};
  bool _getOrderShouldFail = false;
  Object? _getOrderError;

  void setupGetOrder(String id, Order result) {
    _getOrderResults[id] = result;
  }

  void setupGetOrderFailure(Object error) {
    _getOrderShouldFail = true;
    _getOrderError = error;
  }

  @override
  Future<Order> getOrder(String id) async {
    if (_getOrderShouldFail) {
      throw _getOrderError!;
    }
    final result = _getOrderResults[id];
    if (result == null) {
      throw StateError('FakeOrderRepository: no setup for getOrder("$id")');
    }
    return result;
  }

  // --- Capture storage for saveOrder ---
  final List<Order> savedOrders = [];
  bool _saveOrderShouldFail = false;
  Object? _saveOrderError;

  void setupSaveOrderFailure(Object error) {
    _saveOrderShouldFail = true;
    _saveOrderError = error;
  }

  @override
  Future<void> saveOrder(Order order) async {
    if (_saveOrderShouldFail) {
      throw _saveOrderError!;
    }
    savedOrders.add(order);
  }

  // --- Verification helpers ---
  bool get saveOrderWasCalled => savedOrders.isNotEmpty;
  int get saveOrderCallCount => savedOrders.length;

  /// Reset all stubs and captured calls.
  void reset() {
    _getOrderResults.clear();
    _getOrderShouldFail = false;
    _getOrderError = null;
    savedOrders.clear();
    _saveOrderShouldFail = false;
    _saveOrderError = null;
  }
}
```

### Design Principles for Generated Fakes

1. **Query methods** (return data): use a `Map` or variable to store preset
   results. Throw `StateError` if called without setup -- fail fast, clear
   message.

2. **Command methods** (void/side-effect): capture all arguments in a `List`
   for later assertion. Provide `wasCalled`, `callCount`, and argument access.

3. **Failure simulation**: every method has a `setupXxxFailure(error)` method
   so tests can exercise error paths.

4. **Reset**: a single `reset()` method clears all state, useful when a fake
   is shared across tests.

5. **No magic strings at runtime**: the `FakeBuilder.whenCalled('methodName')`
   API is used only in `FeatureSetup` for convenience. The actual fake uses
   typed `setupXxx` methods internally.

---

## 4. Supported External System Types

The `FeatureSetup` / fake mechanism is generic. It is not limited to HTTP
stubs. Below are examples for each category of external system.

### HTTP APIs (Dio, http package)

```dart
abstract class CountryApiClient {
  Future<double> getTaxRate(String countryCode);
  Future<List<Country>> getCountries();
}

// Fake replaces Dio/http entirely -- no network calls
final env = FeatureSetup()
    .fake(countryApi)
        .whenCalled('getTaxRate').returns(0.08)
    .build();
```

### Firebase (Firestore, Auth, Storage)

```dart
abstract class UserRepository {
  Future<UserProfile> getUserProfile(String uid);
  Future<void> updateProfile(UserProfile profile);
}

// Fake replaces FirebaseFirestore -- no Firebase SDK dependency in test
final env = FeatureSetup()
    .fake(userRepository)
        .whenCalled('getUserProfile')
        .returns(UserProfile(name: 'Alice', tier: 'premium'))
    .build();
```

### Local Storage (SharedPreferences, SecureStorage)

```dart
abstract class SettingsStorage {
  Future<String?> getTheme();
  Future<void> setTheme(String theme);
}

final env = FeatureSetup()
    .fake(settingsStorage)
        .whenCalled('getTheme').returns('dark')
    .build();
```

### Local Database (SQLite/Drift, Hive, Isar)

```dart
abstract class CacheRepository {
  Future<List<CachedItem>> getAll();
  Future<void> upsert(CachedItem item);
  Future<void> deleteExpired();
}

final env = FeatureSetup()
    .fake(cacheRepository)
        .whenCalled('getAll')
        .returns([CachedItem(key: 'x', value: '1')])
    .build();
```

### Platform Services (Notifications, Camera, GPS)

```dart
abstract class LocationService {
  Future<LatLng> getCurrentLocation();
  Stream<LatLng> watchLocation();
}

final env = FeatureSetup()
    .fake(locationService)
        .whenCalled('getCurrentLocation')
        .returns(LatLng(40.7128, -74.0060))
    .build();
```

### Clock / DateTime

```dart
abstract class Clock {
  DateTime now();
}

final env = FeatureSetup()
    .fake(clock)
        .whenCalled('now')
        .returns(DateTime(2025, 1, 15, 10, 30))
    .build();
```

### Message Queues / Event Buses

```dart
abstract class EventBus {
  Future<void> publish(DomainEvent event);
  Stream<DomainEvent> subscribe(String topic);
}

final env = FeatureSetup()
    .fake(eventBus)
        .whenCalled('publish').succeeds()
    .build();
```

### Pattern Summary

Every external system follows the same pattern:

```
1. Define a port interface (abstract class)
2. AI generates a fake implementing the interface
3. FeatureSetup configures the fake's behavior
4. Scenario exercises the use case with the fake wired in
```

The mechanism is uniform regardless of whether the real adapter talks to
Firebase, SQLite, a REST API, or a platform channel.

---

## 5. Phantom Type Extension

The existing phantom type system (`NeedsGiven`, `NeedsWhen`, `NeedsThen`,
`ReadyToRun`) requires **no changes** to support component tests.

`FeatureSetup` lives entirely **outside** the scenario chain. It produces a
`TestEnvironment` that is passed to `FeatureScenario` at construction time,
before `.given` is ever called:

```
FeatureSetup          FeatureScenario
(infrastructure)      (behavior specification)
      |                      |
      | .build()             |
      v                      |
TestEnvironment  ----------->| constructor
                             |
                             v
                        .given  (NeedsGiven -> NeedsWhen)
                        .when   (NeedsWhen  -> NeedsThen)
                        .then   (NeedsThen  -> ReadyToRun)
                        .run()
```

The phantom type state machine is untouched:

```dart
// These types remain exactly as they are today:
sealed class ScenarioState {}
final class NeedsGiven extends ScenarioState {}
final class NeedsWhen extends ScenarioState {}
final class NeedsThen extends ScenarioState {}
final class ReadyToRun extends ScenarioState {}
```

The `TestEnvironment` flows through `TestContext`, which already supports
arbitrary key-value storage. No new phantom types are needed.

---

## 6. File Structure for Component Tests

```
test/valenty/features/<feature>/
|-- <feature>_scenario.dart              # FeatureScenario subclass
|-- fakes/                               # AI-generated fakes
|   |-- fake_order_repository.dart
|   |-- fake_country_service.dart
|   +-- fake_payment_gateway.dart
|-- builders/
|   |-- setup/                           # Reusable FeatureSetup factories
|   |   +-- <feature>_setup.dart         # e.g., orderSetup(), orderSetupNoTax()
|   |-- given/
|   |   |-- order_given_builder.dart
|   |   +-- product_given_builder.dart
|   |-- when/
|   |   |-- place_order_when_builder.dart
|   |   +-- cancel_order_when_builder.dart
|   +-- then/
|       |-- order_then_builder.dart
|       +-- order_assertion_builder.dart
+-- scenarios/
    |-- order_pricing_test.dart          # Acceptance tests (no fakes)
    +-- order_tax_component_test.dart    # Component tests (with fakes)
```

### Conventions

- **`fakes/`**: one file per fake, named `fake_<port_name>.dart`. AI-generated,
  human-reviewable.
- **`builders/setup/`**: optional directory for complex or reusable setups.
  Simple tests can inline `FeatureSetup()` directly.
- **Acceptance vs. Component tests**: both live under `scenarios/` but are
  distinguishable by whether they accept a `TestEnvironment`.

---

## 7. Test Last Workflow (Legacy Code)

Valenty targets legacy codebases. The workflow is "Test Last" -- tests capture
existing behavior rather than driving new behavior. The expected outcome is
that tests **pass immediately** (GREEN), because they describe what the code
already does.

### AI-Driven Workflow

```
Step   Action                               Output
----   ------                               ------
 1     AI reads existing code               Identifies port interfaces
                                            (abstract classes) and their
                                            driven adapters (implementations)

 2     AI identifies external boundaries    Lists all driven ports:
                                            - OrderRepository
                                            - PaymentGateway
                                            - NotificationService

 3     AI generates fakes                   Creates fake_order_repository.dart,
                                            fake_payment_gateway.dart, etc.

 4     AI generates FeatureSetup            Creates <feature>_setup.dart with
                                            default configurations that match
                                            the real system's current behavior

 5     AI generates scenarios               Creates component test scenarios
                                            that capture CURRENT behavior:
                                            - what inputs produce what outputs
                                            - what side effects occur

 6     Tests pass immediately               GREEN on first run -- they describe
                                            what IS, not what SHOULD BE

 7     Developer has a safety net           Refactoring is now safe: any
                                            behavioral regression breaks a test
```

### Why GREEN First?

In TDD (Test-Driven Development), you write a failing test first (RED) and
then make it pass. In Test Last for legacy code, the code already exists and
works. The test's job is to lock in that behavior:

```
TDD (new code):         RED  ->  GREEN  ->  REFACTOR
Test Last (legacy):     GREEN (lock behavior)  ->  REFACTOR safely
```

If a Test Last test fails on first run, either:
- The test is wrong (the scenario does not match actual behavior), or
- A bug was discovered (the behavior is not what was expected).

Both outcomes are valuable. But the default expectation is GREEN.

---

## 8. Contract Tests (Future)

### The Problem with Fakes

Fakes can drift from real implementations. If `RealOrderRepository` changes
its behavior but `FakeOrderRepository` is not updated, component tests pass
but the real system fails.

### Dual-Target Contract Tests

Valentina Jemuovic's Dual-Target Contract Test concept addresses this:

```
                  Contract Test
                 /              \
                v                v
    FakeOrderRepository    RealOrderRepository
    (same interface)       (same interface)

    Both must pass the SAME contract test suite.
```

A contract test is a parameterized test suite that runs against any
implementation of a port interface:

```dart
void orderRepositoryContract(OrderRepository Function() factory) {
  test('saves and retrieves an order', () async {
    final repo = factory();
    final order = Order(id: '1', total: 100);
    await repo.saveOrder(order);
    final retrieved = await repo.getOrder('1');
    expect(retrieved.id, equals('1'));
    expect(retrieved.total, equals(100));
  });
}

// Run against fake:
orderRepositoryContract(() => FakeOrderRepository());

// Run against real (narrow integration test):
orderRepositoryContract(() => RealOrderRepository(testDb));
```

This ensures fakes and real implementations stay in sync. Contract test
support is planned for a future phase (see Roadmap).

---

## 9. Backward Compatibility

### Existing Acceptance Tests Work Unchanged

Current Valenty acceptance tests (which have no external dependencies) do not
use `FeatureSetup` or `TestEnvironment`. They continue to work exactly as
before:

```dart
// This still works -- no TestEnvironment needed
OrderScenario('should calculate base price')
    .given
    .product().withUnitPrice(20.00)
    .when
    .placeOrder().withQuantity(5)
    .then
    .order().hasTotalPrice(100.00)
    .run();
```

### Optional Environment Parameter

`FeatureScenario` gains an optional `TestEnvironment?` parameter. When not
provided, the scenario behaves identically to today:

```dart
class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
  OrderScenario(String description, [this.env]) : super(description);

  final TestEnvironment? env;

  @override
  OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    if (env != null) {
      scenario.context.set('__env__', env);
    }
    return OrderGivenBuilder(scenario);
  }
}
```

### No Breaking Changes

| Existing API                          | Change         |
|---------------------------------------|----------------|
| `FeatureScenario`                     | Optional param |
| `ScenarioBuilder`                     | None           |
| `TestContext`                         | None           |
| Phantom types                         | None           |
| `ScenarioRunner`                      | None           |
| All existing builders (Given/When/Then) | None         |

---

## 10. Implementation Roadmap

### Phase 1: Core Infrastructure Classes

**Goal:** Ship `FeatureSetup`, `FakeBuilder`, and `TestEnvironment`.

- [ ] `FeatureSetup` class with `.fake()` and `.build()` fluent API
- [ ] `FakeBuilder<T>` with `.whenCalled()`, `.returns()`, `.succeeds()`,
      `.fails()`, `.returnsInOrder()`
- [ ] `TestEnvironment` immutable container with `.get<T>()` and `.has<T>()`
- [ ] `FeatureScenario` updated with optional `TestEnvironment?` parameter
- [ ] Unit tests for all new classes

### Phase 2: AI Skill Updates

**Goal:** Teach the AI to generate fakes and setups.

- [ ] Update Claude skill template with fake generation instructions
- [ ] Update Cursor rule template with fake generation patterns
- [ ] Update Codex agent template with fake generation guidance
- [ ] Update OpenCode agent template
- [ ] Add introspection support for detecting port interfaces in user projects

### Phase 3: Example Projects

**Goal:** Demonstrate the full component test workflow.

- [ ] Extend the existing Order example with a driven port (e.g., tax service)
- [ ] Add generated fakes to the example
- [ ] Add component test scenarios using `FeatureSetup`
- [ ] Add documentation comments and usage examples

### Phase 4: Contract Test Support

**Goal:** Enable dual-target contract testing.

- [ ] `ContractTest` base class or runner
- [ ] AI generates contract test suites alongside fakes
- [ ] Example showing same contract run against fake and real implementation
- [ ] Integration with narrow test tooling

---

## Appendix: Full API Example

```dart
// ============================================================
// INFRASTRUCTURE: Configure fakes (separate from scenario)
// ============================================================
final taxEnv = FeatureSetup()
    .fake(countryService)
        .whenCalled('getTaxRate')
        .returns(0.08)
    .and
    .fake(orderRepository)
        .whenCalled('save')
        .succeeds()
    .build();

// ============================================================
// SCENARIO: Business behavior (pure domain, reads like a spec)
// ============================================================
OrderScenario('should calculate total with tax', taxEnv)
    .given
    .product()
        .withUnitPrice(20.00)
    .when
    .placeOrder()
        .withQuantity(5)
    .then
    .order()
        .hasTaxAmount(8.00)
        .hasTotalPrice(108.00)
    .run();

// ============================================================
// REUSE: Multiple scenarios share same infrastructure
// ============================================================
OrderScenario('should apply tax to single item', taxEnv)
    .given
    .product()
        .withUnitPrice(50.00)
    .when
    .placeOrder()
        .withQuantity(1)
    .then
    .order()
        .hasTaxAmount(4.00)
        .hasTotalPrice(54.00)
    .run();

// ============================================================
// ERROR PATH: Test failure scenarios
// ============================================================
final failEnv = FeatureSetup()
    .fake(orderRepository)
        .whenCalled('save')
        .fails(DatabaseException('connection lost'))
    .build();

OrderScenario('should handle save failure gracefully', failEnv)
    .given
    .product()
        .withUnitPrice(20.00)
    .when
    .placeOrder()
        .withQuantity(1)
    .then
    .order()
        .hasError('Failed to save order')
    .run();
```
