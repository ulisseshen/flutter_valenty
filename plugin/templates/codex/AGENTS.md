# Valenty — AI-Powered Component Testing for Flutter

## What is Valenty?

Valenty generates component tests for Flutter apps using the valentyTest pattern.
Tests read like user stories — no `find.byKey`, no `tester.tap` in test bodies.

## Setup

Add to pubspec.yaml:
```yaml
dev_dependencies:
  valenty_test: ^0.2.3
```

Then run `flutter pub get`.

## How to Write Tests

### 1. For each feature, create 4 files:

```
test/valenty/
├── <feature>_test_helper.dart      # valentyTest() wrapper
├── dsl/
│   ├── <feature>_backend_stub.dart # Fakes: stubExpenses(), stubBudget()
│   ├── <feature>_system_dsl.dart   # Actions: openApp(), addExpense()
│   └── <feature>_ui_driver.dart    # Widget interactions: tap, enter, verify
└── scenarios/
    └── <feature>_test.dart         # Test scenarios
```

### 2. Test Helper wraps testWidgets:

```dart
void valentyTest(String description, {
  void Function(BackendStub backend)? setup,
  required Future<void> Function(SystemDsl system, BackendStub backend) body,
}) {
  testWidgets(description, (tester) async {
    final backend = BackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = UiDriver(tester);
      final system = SystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
```

### 3. Write scenarios in domain language:

```dart
valentyTest(
  'displays total after adding expense',
  setup: (backend) {
    backend.stubExpenses(ExpenseFixtures.list);
  },
  body: (system, backend) async {
    await system.openApp();
    system.verifyTotal('4.50');
  },
);
```

## Rules

- Test names describe user-observable behavior, not implementation
- Never inline test data — use fixture classes (abstract final, deterministic)
- Manual fakes only — no mocktail/mockito
- Use `parameterizedTest` from valenty_test for input variations
- Services need `@visibleForTesting` override points for BackendStub

## Credits

Built on the [Modern Test Pyramid](https://journal.optivem.com/p/modern-test-pyramid) by [Valentina Jemuovic](https://www.linkedin.com/in/valentinajemuovic/).
