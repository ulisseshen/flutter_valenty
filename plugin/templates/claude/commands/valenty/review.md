---
name: valenty:review
description: Review existing tests for quality — naming, fragility, coupling, inline data
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Bash
  - AskUserQuestion
---

<objective>
Review all test files for quality issues and offer to auto-fix.
</objective>

<process>

## Step 1: Find all test files

```
Glob: test/**/*_test.dart
```

## Step 2: Check naming

Scan every test name. Flag any that:
- Mention method names ("should call save()")
- Mention class names ("should return UserDto")
- Are vague ("works correctly", "test verifyPin")
- Start with "test" or "should call"

## Step 3: Check fragility

Look for in test files:

**CRITICAL:**
- `DateTime.now()` → use fixture dates
- `Future.delayed()` / `sleep()` → use pumpAndSettle
- `Random()` without seed → use fixtures
- Shared mutable state between tests → fresh state in setUp
- Missing `tearDown` for setup state

**WARNING:**
- `pump()` without `pumpAndSettle()`
- Magic numbers in assertions
- `setUpAll` with mutable state

**SMELL:**
- Inline test data (should be fixtures)
- `skip: true` annotations
- Commented-out test code
- Test file > 500 lines

## Step 4: Check coupling

For each test, ask: would it break if we:
- Changed an internal method signature?
- Moved a method between classes?
- Merged or split internal classes?

If YES → coupled to implementation.

## Step 5: Check stubs and fakes

Review all test doubles (stubs, fakes) for:

**Over-mocking:** If > 50% of a test is mock/stub setup, it's testing mocks not code.
**Stale stubs:** Stubs that don't match current service interfaces.
**Missing restore:** BackendStubDsl without `restore()` in tearDown → state leaks.
**Duplicate stubs:** Same fake class reimplemented in multiple test files → centralize.

## Step 6: Check matchers

- Are custom matchers implementing `describeMismatch`? If not → useless error messages.
- Are there repeated complex assertions that should be matchers? (3+ occurrences)
- Are finders reusable or duplicated across test files?

## Step 7: Report

```
## Valenty Test Quality Report

**Scanned**: X files | Y tests
**Verdict**: CLEAN / PROBATION / CONDEMNED

### Naming Issues (X)
- file_test.dart — "should call repo.save()" → "saves expense to storage"

### Fragility (X critical, Y warning)
- file_test.dart:42 — DateTime.now() → use fixture date

### Coupling (X tests)
- file_test.dart — mocks internal validator → test via public API

### Inline Data (X violations)
- file_test.dart:15 — Expense(...) inline → use ExpenseFixtures.valid

### Stubs/Fakes (X issues)
- file_test.dart — over-mocked: 15 lines of stub setup for 3 lines of test
- fake_repo.dart — missing restore(), state leaks between tests

### Matchers (X issues)
- file_test.dart — repeated assertion (5x) should be a custom matcher
- custom_matcher.dart — missing describeMismatch
```

## Step 8: Ask about auto-fix

Use **AskUserQuestion** (multiSelect):
```
question: "Found issues. What should I fix?"
options:
  - Fix test names (rename to behavioral)
  - Fix fragile patterns (DateTime.now, sleep, etc.)
  - Extract inline data to fixtures
  - Fix all issues
```

Apply selected fixes, re-run tests, verify they pass.

</process>
