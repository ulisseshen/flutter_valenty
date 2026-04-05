---
description: Review existing tests for quality — naming, fragility, coupling, inline data
---

// turbo

## 1. Find all test files

Search for all `*_test.dart` files under the `test/` directory.

## 2. Check naming

Scan every test name. Flag any that:
- Mention method names ("should call save()")
- Mention class names ("should return UserDto")
- Are vague ("works correctly", "test verifyPin")
- Start with "test" or "should call"

## 3. Check fragility

Look for in test files:

**CRITICAL:**
- `DateTime.now()` — use fixture dates
- `Future.delayed()` / `sleep()` — use pumpAndSettle
- `Random()` without seed — use fixtures
- Shared mutable state between tests — fresh state in setUp
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

## 4. Check coupling

For each test, ask: would it break if we:
- Changed an internal method signature?
- Moved a method between classes?
- Merged or split internal classes?

If YES — coupled to implementation.

## 5. Report

Present the findings in this format:

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
```

## 6. Ask about auto-fix

Ask the user what to fix:

"Found issues. What should I fix?"
- Fix test names (rename to behavioral)
- Fix fragile patterns (DateTime.now, sleep, etc.)
- Extract inline data to fixtures
- Fix all issues

Apply selected fixes, re-run tests, verify they pass.
