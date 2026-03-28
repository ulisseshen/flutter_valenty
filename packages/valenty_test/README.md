# valenty_test

Compile-time safe component testing DSL for Flutter apps with phantom types and typed fluent builders.

Part of the [Valenty](https://github.com/valenty-dev/valenty) testing framework.

## Installation

```yaml
dev_dependencies:
  valenty_test: ^0.1.0
```

## Usage

### valentyTest (Primary — UI-first component tests)

```dart
valentyTest(
  'should show total after adding expense',
  setup: (backend) {
    backend.stubExpenses([Expense(amount: 4.50)]);
  },
  body: (system, backend) async {
    await system.openApp();
    await system.verifyTotal('4.50');
  },
);
```

### Typed Builders (Secondary — pure logic tests)

```dart
OrderScenario('should calculate base price')
    .given.product().withUnitPrice(20.00)
    .when.placeOrder().withQuantity(5)
    .then.order().hasBasePrice(100.00)
    .run();
```

## Key Classes

- `SystemDsl` — base for domain-language user actions
- `BackendStubDsl` — base for managing singleton factory overrides
- `UiDriver` — abstract base for widget interaction (extend with WidgetTester)
- `TestEnvironment` — infrastructure setup/teardown before scenarios
- `FeatureScenario` — entry point for typed builder chains
- `ScenarioRunner` — executes scenarios as package:test tests

## Documentation

See the [full documentation](https://github.com/valenty-dev/valenty) for:
- Modern Test Pyramid methodology
- valentyTest architecture
- @visibleForTesting patterns
- Example projects (7 examples, 118+ tests)

## License

MIT
