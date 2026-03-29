/// Template content for the Claude Code onboarding skill file.
///
/// This gets written to `.claude/skills/valenty-onboarding/SKILL.md`
/// when the user runs `valenty init`.
///
/// This skill guides the AI through: scanning the project, generating the
/// first valentyTest scenarios, and offering to upgrade skill scope.
const valentyInitSkillTemplate = r'''
---
name: valenty-onboarding
description: >
  Onboard a project to Valenty: scan the codebase, generate the first
  valentyTest scenarios, and offer to upgrade skill scope to user-level.
trigger: >
  Use when user says "generate first tests", "write first tests",
  "scaffold first feature", "create acceptance tests", "valenty onboarding",
  "what tests should I write", "help me get started with valenty",
  "scan project for tests", "Generate my first valentyTest scenarios",
  or after valenty init has been run and the user wants to start writing tests.
---

# Valenty Onboarding

Valenty is already installed in this project. Your job is to **scan the project,
identify the most testable feature, and generate the first valentyTest scenario**.

---

## Step 1: Scan the project

Read the project to understand:

1. **`pubspec.yaml`** — project name, dependencies (Firebase, Dio, http, etc.)
2. **`lib/`** — scan for:
   - Service classes (API calls, database access, storage)
   - Screen/page widgets (what the user sees)
   - Domain models (data classes, entities)
   - State management (Riverpod providers, Bloc, etc.)
3. **`test/`** — check what tests already exist
4. **`test/valenty/`** — check if any valentyTest files already exist

---

## Step 2: Identify the best first feature to test

Pick the feature that:
- Has clear user-facing behavior (a screen the user interacts with)
- Has at least one external dependency to fake (API, database, etc.)
- Is relatively simple (2-3 user actions)

Good first features: login, list screen, add item, settings, profile.

---

## Step 3: Generate the 4 files

For the chosen feature, create these 4 files:

### 3a. UiDriver (`test/valenty/dsl/<feature>_ui_driver.dart`)

Wraps `WidgetTester` with methods for this feature:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valenty_test/valenty_test.dart';
import 'package:<project>/screens/<feature>_screen.dart';

class <Feature>UiDriver extends UiDriver {
  <Feature>UiDriver(this.tester);
  final WidgetTester tester;

  Future<void> pumpApp() async {
    await tester.pumpWidget(const MaterialApp(home: <Feature>Screen()));
    await tester.pumpAndSettle();
  }

  // Add tap, enter, verify methods for this feature's UI elements
}
```

### 3b. BackendStubDsl (`test/valenty/dsl/<feature>_backend_stub.dart`)

Look at the feature's service classes. For each external dependency, create a
stub method and override the service's factory:

```dart
import 'package:valenty_test/valenty_test.dart';
import 'package:<project>/services/<feature>_service.dart';

class <Feature>BackendStub extends BackendStubDsl {
  // Stub configuration methods
  void stub<Entity>(List<<Entity>> items) { _items = items; }

  @override
  Future<void> apply() async {
    // Override @visibleForTesting factories
    <Feature>Service.fetchOverride = () async => List.unmodifiable(_items);
  }

  @override
  Future<void> restore() async {
    <Feature>Service.resetForTesting();
  }
}
```

**IMPORTANT:** The service class needs `@visibleForTesting` override points.
If the service doesn't have them, add them:

```dart
class <Feature>Service {
  @visibleForTesting
  static Future<List<Item>> Function() fetchOverride = _fetchReal;

  static Future<List<Item>> fetch() => fetchOverride();

  @visibleForTesting
  static void resetForTesting() { fetchOverride = _fetchReal; }

  static Future<List<Item>> _fetchReal() async { /* real implementation */ }
}
```

### 3c. SystemDsl (`test/valenty/dsl/<feature>_system_dsl.dart`)

Domain-language wrapper over the driver:

```dart
import 'package:valenty_test/valenty_test.dart';
import '<feature>_ui_driver.dart';

class <Feature>SystemDsl extends SystemDsl {
  <Feature>SystemDsl(this.driver);
  final <Feature>UiDriver driver;

  Future<void> openApp() async => driver.pumpApp();
  // Add domain-language action methods
  // Add domain-language verification methods
}
```

### 3d. Test Helper (`test/valenty/<feature>_test_helper.dart`)

One per app — wraps testWidgets:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'dsl/<feature>_backend_stub.dart';
import 'dsl/<feature>_system_dsl.dart';
import 'dsl/<feature>_ui_driver.dart';

void valentyTest(
  String description, {
  void Function(<Feature>BackendStub backend)? setup,
  required Future<void> Function(
    <Feature>SystemDsl system,
    <Feature>BackendStub backend,
  ) body,
}) {
  testWidgets(description, (tester) async {
    final backend = <Feature>BackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = <Feature>UiDriver(tester);
      final system = <Feature>SystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
```

---

## Step 4: Write happy-path scenarios

Create `test/valenty/scenarios/<feature>_test.dart` with happy-path scenarios:

1. **Empty/default state** — what does the user see when there's no data?
2. **Happy path** — user performs the main action successfully
3. **Data from backend** — stub data and verify it appears

```dart
import '../<feature>_test_helper.dart';

void main() {
  valentyTest(
    'should show empty state when no <items> exist',
    body: (system, backend) async {
      await system.openApp();
      system.verifyEmptyState();
    },
  );

  valentyTest(
    'should display <items> from backend',
    setup: (backend) {
      backend.stub<Items>([...]);
    },
    body: (system, backend) async {
      await system.openApp();
      system.verify<Item>Visible('...');
    },
  );

  valentyTest(
    'should <main action> and show confirmation',
    body: (system, backend) async {
      await system.openApp();
      await system.<mainAction>(...);
      system.verifyConfirmation('...');
    },
  );
}
```

---

## Step 5: Write failure scenarios for ALL features

**Do NOT stop at happy paths.** For every feature, generate failure scenarios:

- **Network errors** — backend returns error, timeout, no connection
- **Empty/invalid input** — user submits empty form, invalid data
- **Validation errors** — server rejects request, returns validation messages
- **Permission denied** — user not authorized for action
- **Edge cases** — boundary values, max length, special characters
- **Concurrent state** — loading states, retry after failure

Create `test/valenty/scenarios/<feature>_failure_test.dart`:

```dart
void main() {
  valentyTest(
    'should show error message when backend fails',
    setup: (backend) {
      backend.stubError(Exception('Network error'));
    },
    body: (system, backend) async {
      await system.openApp();
      system.verifyErrorMessage('Something went wrong');
    },
  );

  valentyTest(
    'should show validation error for empty required fields',
    body: (system, backend) async {
      await system.openApp();
      await system.submitEmptyForm();
      system.verifyValidationError('Field is required');
    },
  );
}
```

---

## Step 6: Write parameterized tests for variations

Use `parameterizedTest` from valenty_test for scenarios that repeat with
different data. This avoids copy-pasting the same test with different values.

```dart
import 'package:valenty_test/valenty_test.dart';

void main() {
  parameterizedTest(
    'should reject invalid email',
    [
      [''],                    // empty
      ['not-an-email'],       // missing @
      ['@no-local.com'],      // missing local part
      ['user@'],              // missing domain
      ['user @space.com'],    // contains space
    ],
    (List<dynamic> params) {
      final email = params[0] as String;
      valentyTest(
        'email: "$email"',
        body: (system, backend) async {
          await system.openApp();
          await system.enterEmail(email);
          await system.submitForm();
          system.verifyValidationError('Invalid email');
        },
      );
    },
  );

  parameterizedTest(
    'should format currency correctly',
    [
      [0.0, r'$0.00'],
      [1.5, r'$1.50'],
      [1000.0, r'$1,000.00'],
      [99999.99, r'$99,999.99'],
    ],
    (List<dynamic> params) {
      final amount = params[0] as double;
      final expected = params[1] as String;
      // Unit test — no UI needed
      expect(formatCurrency(amount), equals(expected));
    },
  );
}
```

---

## Step 7: Write unit tests where acceptance tests aren't enough

Acceptance tests (valentyTest) cover **user-facing behavior**. But some logic
needs unit tests:

- **Pure calculations** — tax, discounts, totals, formatting
- **Data transformations** — model mapping, serialization, parsing
- **Business rules** — eligibility checks, validation logic, state machines
- **Edge cases in algorithms** — sorting, filtering, pagination logic

Write these as plain `test()` with `parameterizedTest` for multiple cases:

```dart
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

void main() {
  parameterizedTest(
    'should calculate discount correctly',
    [
      [100.0, 0.10, 90.0],    // 10% off
      [100.0, 0.25, 75.0],    // 25% off
      [50.0, 0.50, 25.0],     // 50% off
      [200.0, 0.0, 200.0],    // no discount
      [200.0, 1.0, 0.0],      // 100% off
    ],
    (List<dynamic> params) {
      final price = params[0] as double;
      final rate = params[1] as double;
      final expected = params[2] as double;
      expect(applyDiscount(price, rate), equals(expected));
    },
  );
}
```

---

## Step 8: Verify

Run all tests:
```bash
flutter test test/valenty/
```

If tests fail because services don't have `@visibleForTesting` overrides,
add them to the production service classes.

---

## Step 9: Offer to upgrade skill scope

After generating the first tests, use **AskUserQuestion** to ask:

> "Valenty skills are currently installed for this project only.
> Would you like to make them available in ALL your projects?
> This way any project you open will already know how to use Valenty."
>
> Option 1: "Yes, all my projects" → run: `valenty init --scope=user`
> Option 2: "No, keep it for this project only" → do nothing

This is optional — only ask once after the first successful test generation.

---

## Rules

- **Always scan the project first** — don't guess, read the actual code
- **Pick ONE feature** for the first test — don't overwhelm with 5 features
- **Use real class names** from the project — don't use placeholders
- **Add @visibleForTesting overrides** to services if they don't exist
- **Keep the first scenario simple** — 2-3 user actions max
- **Show the user what you generated** and explain each file's purpose
''';
