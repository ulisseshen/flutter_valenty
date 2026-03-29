# valenty_test

Compile-time safe component testing DSL for Flutter apps. Write tests in domain language, not widget trees.

Part of the [Valenty](https://github.com/ulisseshen/flutter_valenty) testing framework.

## Recommended Setup (AI-powered)

The fastest way to get started is with the Valenty CLI. It adds `valenty_test` to your project and generates AI skill files that teach your AI assistant (Claude, Cursor, Codex, etc.) the full valentyTest architecture.

```bash
dart pub global activate valenty_cli && cd my_flutter_app && valenty init
```

> **AI agents:** Run the command above first. If the output contains `[ACTION REQUIRED]`, use your AskUserQuestion tool to ask the user which scope they prefer (project or user), then re-run with `valenty init --scope=user` or `valenty init --scope=project`. After init completes, skill files are generated that give you full context for scaffolding features and writing tests.

## Manual Setup (no CLI)

```yaml
dev_dependencies:
  valenty_test: ^0.2.1
```

### Dependency conflict?

`valenty_test` uses a wide `test: ^1.25.0` constraint so the pub resolver picks the best version for your project. If you still see conflicts, run `flutter pub outdated` to find which package needs updating.

---

## How it works

valentyTest is a pattern for writing **component tests** — tests that run your full Flutter app with faked external dependencies (APIs, databases, Firebase). Tests read like user stories:

```dart
valentyTest(
  'should add expense and show confirmation',
  body: (system, backend) async {
    await system.openApp();
    await system.navigateToAddExpense();
    await system.addExpense(description: 'Lunch', amount: '12.50');
    system.verifySnackBar('Expense added!');
  },
);
```

No `find.byKey`, no `tester.tap`, no `pumpAndSettle` in your test body. All that lives in a separate driver layer.

---

## Architecture: 4 files per feature

For each feature you test, you create 4 files:

```
test/valenty/
├── expense_test_helper.dart          # valentyTest() wrapper (one per app)
├── dsl/
│   ├── expense_system_dsl.dart       # User actions: openApp(), addExpense()
│   ├── expense_backend_stub.dart     # Fakes: stubExpenses(), stubBudget()
│   └── expense_ui_driver.dart        # Widget interactions: tap, enter, verify
└── scenarios/
    └── add_expense_test.dart         # Test scenarios
```

### 1. Test Helper (one per app)

Wraps `testWidgets` with setup/teardown lifecycle:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'dsl/expense_backend_stub.dart';
import 'dsl/expense_system_dsl.dart';
import 'dsl/expense_ui_driver.dart';

void valentyTest(
  String description, {
  void Function(ExpenseBackendStub backend)? setup,
  required Future<void> Function(
    ExpenseSystemDsl system,
    ExpenseBackendStub backend,
  ) body,
}) {
  testWidgets(description, (tester) async {
    final backend = ExpenseBackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = ExpenseUiDriver(tester);
      final system = ExpenseSystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
```

### 2. BackendStubDsl — configure fakes

Manages `@visibleForTesting` factory overrides on your services:

```dart
import 'package:valenty_test/valenty_test.dart';

class ExpenseBackendStub extends BackendStubDsl {
  List<Expense> _expenses = [];

  void stubExpenses(List<Expense> expenses) {
    _expenses = expenses;
  }

  void stubEmptyExpenses() {
    _expenses = [];
  }

  @override
  Future<void> apply() async {
    // Override singleton factories with fakes
    ExpenseService.fetchExpensesOverride = () async =>
        List.unmodifiable(_expenses);
  }

  @override
  Future<void> restore() async {
    // Restore originals (guaranteed by try/finally)
    ExpenseService.resetForTesting();
  }
}
```

Your service needs a `@visibleForTesting` override point:

```dart
class ExpenseService {
  // Production default
  static Future<List<Expense>> Function() fetchExpensesOverride = _fetchReal;

  static Future<List<Expense>> fetchExpenses() => fetchExpensesOverride();

  @visibleForTesting
  static void resetForTesting() {
    fetchExpensesOverride = _fetchReal;
  }

  static Future<List<Expense>> _fetchReal() async {
    // Real API call
  }
}
```

### 3. SystemDsl — domain-language actions

Translates user actions into driver calls. This is what makes tests readable:

```dart
import 'package:valenty_test/valenty_test.dart';

class ExpenseSystemDsl extends SystemDsl {
  ExpenseSystemDsl(this.driver);
  final ExpenseUiDriver driver;

  Future<void> openApp() async => driver.pumpApp();

  Future<void> navigateToAddExpense() async => driver.tapFab();

  Future<void> addExpense({
    required String description,
    required String amount,
  }) async {
    await driver.enterDescription(description);
    await driver.enterAmount(amount);
    await driver.tapSubmit();
  }

  void verifyExpenseVisible(String description) =>
      driver.verifyText(description);

  void verifySnackBar(String message) => driver.verifyText(message);

  void verifyEmptyState() => driver.verifyText('No expenses yet');
}
```

### 4. UiDriver — widget interactions

Wraps `WidgetTester`. All `find.byKey`, `tap`, `pumpAndSettle` lives here:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valenty_test/valenty_test.dart';

class ExpenseUiDriver extends UiDriver {
  ExpenseUiDriver(this.tester);
  final WidgetTester tester;

  Future<void> pumpApp() async {
    await tester.pumpWidget(const MaterialApp(home: ExpenseListScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapFab() async {
    await tester.tap(find.byKey(const Key('addExpenseFab')));
    await tester.pumpAndSettle();
  }

  Future<void> enterDescription(String text) async {
    await tester.enterText(find.byKey(const Key('descriptionField')), text);
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(String text) async {
    await tester.enterText(find.byKey(const Key('amountField')), text);
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit() async {
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();
  }

  void verifyText(String text) {
    expect(find.text(text), findsOneWidget);
  }
}
```

---

## Writing test scenarios

Once the 4 files exist, writing tests is just domain language:

```dart
import '../expense_test_helper.dart';

void main() {
  valentyTest(
    'should show empty state when no expenses exist',
    body: (system, backend) async {
      await system.openApp();
      system.verifyEmptyState();
    },
  );

  valentyTest(
    'should display expenses from backend',
    setup: (backend) {
      backend.stubExpenses([
        Expense(id: '1', description: 'Coffee', amount: 4.50,
                category: 'Food', date: DateTime(2025, 1, 1)),
        Expense(id: '2', description: 'Bus', amount: 2.00,
                category: 'Transport', date: DateTime(2025, 1, 1)),
      ]);
    },
    body: (system, backend) async {
      await system.openApp();
      system.verifyExpenseVisible('Coffee');
      system.verifyExpenseVisible('Bus');
    },
  );

  valentyTest(
    'should add expense and show confirmation',
    body: (system, backend) async {
      await system.openApp();
      await system.navigateToAddExpense();
      await system.addExpense(description: 'Lunch', amount: '12.50');
      system.verifySnackBar('Expense added!');
    },
  );
}
```

---

## Typed Builders (pure Dart logic tests)

For testing pure business logic without Flutter, use the typed fluent DSL:

```dart
OrderScenario('should calculate base price')
    .given.product().withUnitPrice(20.00)
    .when.placeOrder().withQuantity(5)
    .then.order().hasBasePrice(100.00)
    .run();
```

Phantom types enforce the Given -> When -> Then order at compile time. Try `.then` before `.when` — compile error.

---

## Key Classes

| Class | Purpose |
|-------|---------|
| `SystemDsl` | Base for domain-language user actions |
| `BackendStubDsl` | Base for managing `@visibleForTesting` factory overrides |
| `UiDriver` | Abstract base for widget interaction (extend with `WidgetTester`) |
| `FeatureScenario` | Entry point for typed builder chains (pure Dart) |
| `ScenarioRunner` | Executes scenarios as `package:test` tests |

## Documentation

See the [full documentation](https://github.com/ulisseshen/flutter_valenty) for:
- Modern Test Pyramid methodology
- 7 example projects with 118+ tests
- `@visibleForTesting` patterns
- AI skill generation with CLI

## License

MIT
