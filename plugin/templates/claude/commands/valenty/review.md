---
name: valenty:review
description: Review existing tests for quality — spawns parallel agents for naming, fragility, coupling, fixtures, finders/matchers
argument-hint: "[path]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Bash
  - Agent
  - AskUserQuestion
---

<objective>
Review test quality by spawning parallel agents for independent review tasks.
Each agent has direct, assertive instructions. Results are merged into a single report.
</objective>

<process>

## Step 1: Discover test scope

If `$ARGUMENTS` has a path, use it. Otherwise find all test files:

```
Glob: test/**/*_test.dart
```

Count total files and tests. Store as `$TEST_FILES` and `$TEST_DIR`.

## Step 2: Launch parallel review agents

Spawn **4 agents in parallel** — each reviews one independent dimension.
Use a single message with multiple Agent tool calls.

### Agent 1: Test Name Reviewer

```
Agent(
  description="Review test names",
  prompt="You are a strict test name reviewer. Read ALL _test.dart files in $TEST_DIR.

REJECT any test name that:
- Mentions method names: 'should call save()', 'calls repository.fetch()'
- Mentions class names: 'should return UserDto', 'creates OrderService'
- Is vague: 'works correctly', 'test verifyPin', 'handles error'
- Starts with 'test' or 'should call'
- Describes HOW instead of WHAT

APPROVE names that describe user-observable behavior:
- 'displays total after adding expense'
- 'rejects login with invalid email'
- 'shows error when network fails'

For each rejected name, provide the EXACT fix:
- File path and line number
- Current name (bad)
- Suggested name (behavioral)

Output format:
## Test Name Review
**Files scanned:** X
**Issues:** Y

| File | Line | Current (bad) | Suggested (behavioral) |
|------|------|--------------|----------------------|
| ... | ... | ... | ... |
"
)
```

### Agent 2: Fragile Test Hunter

```
Agent(
  description="Hunt fragile tests",
  prompt="You are a merciless fragile test hunter. ZERO tolerance for flaky patterns.
Scan ALL _test.dart files in $TEST_DIR.

Check for these patterns with EXACT line numbers:

CRITICAL (will break CI):
- DateTime.now() in test code → FIX: use fixture date DateTime(2025, 1, 15)
- Future.delayed() / sleep() → FIX: use pumpAndSettle() or fakeAsync
- Random() without seed → FIX: use Random(42) or fixture data
- Shared mutable state (top-level vars modified across tests) → FIX: fresh in setUp()
- Missing tearDown for setUp state → FIX: add tearDown
- Network calls without fakes → FIX: use BackendStubDsl

WARNING (likely to flake):
- pump() without pumpAndSettle() after user interaction
- Magic numbers in assertions
- setUpAll with mutable state

SMELL (poor practice):
- Inline test data (Expense(...) instead of ExpenseFixtures.valid)
- skip: true annotations — CHECK if feature is now implemented, if so REMOVE skip
- Commented-out test code — DELETE it, git remembers
- Test file > 500 lines — SPLIT it

FLUTTER-SPECIFIC:
- Raw Screen widgets in test drivers instead of Page wrappers
- Missing ProviderScope overrides in acceptance tests

Output format:
## Fragile Test Report
**Verdict:** CONDEMNED / PROBATION / CLEAN

### CRITICAL (X)
- `file:line` — pattern found → fix

### WARNING (X)
- `file:line` — pattern found → fix

### SMELL (X)
- `file:line` — pattern found → fix
"
)
```

### Agent 3: Fixture & Stub Reviewer

```
Agent(
  description="Review fixtures and stubs",
  prompt="You review test data quality. Scan ALL _test.dart files and test helper files in $TEST_DIR.

CHECK FIXTURES:
- Find ALL inline test data (constructing domain objects directly in tests)
- For each: suggest using or creating a fixture class
- Check existing fixtures in test/mocks/fixtures/ — are they deterministic?
- Flag any DateTime.now(), Random(), or non-deterministic values in fixtures
- Check cross-references: do related fixtures reference each other's IDs?

CHECK STUBS/FAKES:
- Find all classes extending BackendStubDsl or implementing interfaces for testing
- Over-mocking: if >50% of test is stub setup, flag it
- Missing restore(): every apply() MUST have a matching restore() in finally/tearDown
- Stale stubs: does the stub interface match the current production interface?
- Duplicate stubs: same fake reimplemented in multiple files → centralize

Output format:
## Fixture & Stub Review

### Inline Data (centralize to fixtures)
| File | Line | Inline Code | Suggested Fixture |
|------|------|------------|------------------|

### Stub Issues
| File | Issue | Fix |
|------|-------|-----|

### Missing Fixtures (create these)
- EntityName → create test/mocks/fixtures/entity_name_fixtures.dart
"
)
```

### Agent 4: Finder & Matcher Reviewer

```
Agent(
  description="Review finders and matchers",
  prompt="You review test helpers for reusability. Scan $TEST_DIR.

CHECK FINDERS:
- Find repeated find.byKey/find.text/find.byType patterns used 3+ times
- For each: suggest creating a reusable finder in UiDriver or test/helpers/
- Check existing finders — are they properly scoped (find.descendant)?
- Flag find.byWidgetPredicate without description parameter

CHECK MATCHERS:
- Find custom matchers (extends Matcher) — do they implement describeMismatch?
- Missing describeMismatch = REJECT (error messages will be useless)
- Find repeated complex expect() patterns used 3+ times → suggest custom matcher
- Check matcher error messages — are they helpful?

CHECK ASSERTION QUALITY:
- Flag weak assertions: expect(result, isNotNull), expect(list, isNotEmpty)
- These pass when they shouldn't — suggest specific value assertions

Output format:
## Finder & Matcher Review

### Reusable Finders (extract these)
| Pattern | Occurrences | Suggested Finder |
|---------|------------|-----------------|

### Matcher Issues
| File | Issue | Fix |
|------|-------|-----|

### Weak Assertions
| File | Line | Current | Suggested |
|------|------|---------|-----------|
"
)
```

## Step 3: Merge reports

Wait for all 4 agents to complete. Merge their outputs into a single report:

```
═══════════════════════════════════════════════
  VALENTY TEST QUALITY REPORT
═══════════════════════════════════════════════

Scanned: X files | Y tests
Verdict: CLEAN / PROBATION / CONDEMNED

[Agent 1 output: Test Name Review]
[Agent 2 output: Fragile Test Report]
[Agent 3 output: Fixture & Stub Review]
[Agent 4 output: Finder & Matcher Review]

═══════════════════════════════════════════════
```

## Step 4: Ask what to fix

Use **AskUserQuestion** (multiSelect):

```
question: "Found X issues across 4 dimensions. What should I fix?"
options:
  - Fix test names (rename to behavioral)
  - Fix fragile patterns (DateTime.now, sleep, skip:true)
  - Extract inline data to fixtures + fix stubs
  - Create reusable finders and matchers
```

## Step 5: Fix selected issues

For each selected fix category, apply changes directly.
After fixing, run:

```bash
dart run valenty_test:failed_tests
```

Verify all tests still pass after fixes.

</process>
