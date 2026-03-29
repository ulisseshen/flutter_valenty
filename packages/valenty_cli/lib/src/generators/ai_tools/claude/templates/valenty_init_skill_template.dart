/// Template content for the Claude Code post-init skill file.
///
/// This gets written to `.claude/skills/valenty-first-tests/SKILL.md`
/// in the user's project when they run `valenty init`.
///
/// This skill teaches AI how to scan the project and generate the first
/// valentyTest scenarios after Valenty is installed.
const valentyInitSkillTemplate = r'''
---
name: valenty-first-tests
description: >
  Scan the project, identify features and services, and generate the first
  valentyTest scenarios (test helper, SystemDsl, BackendStubDsl, UiDriver).
trigger: >
  Use when user says "generate first tests", "write first tests",
  "scaffold first feature", "create acceptance tests", "valenty first tests",
  "what tests should I write", "help me get started with valenty",
  "scan project for tests", or after valenty init has been run and the user
  wants to start writing tests.
---

# Valenty: Generate First Tests

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

## Step 4: Write the first 3 test scenarios

Create `test/valenty/scenarios/<feature>_test.dart` with 3 scenarios:

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

## Step 5: Verify

Run the tests:
```bash
flutter test test/valenty/
```

If tests fail because services don't have `@visibleForTesting` overrides,
add them to the production service classes.

---

## Step 6: Offer to upgrade skill scope

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
