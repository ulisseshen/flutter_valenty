# Valenty

**AI-first compile-time safe acceptance testing for Dart & Flutter.**

Valenty replaces fragile string-based Gherkin with a typed fluent DSL where **the compiler catches errors before you run any test**. The CLI is just an installer -- AI does the heavy lifting: scaffolding builders, writing tests, and maintaining the DSL.

```dart
OrderScenario('should calculate base price as product of unit price and quantity')
    .given
    .product()
        .withUnitPrice(20.00)
    .when
    .placeOrder()
        .withQuantity(5)
    .then
    .shouldSucceed()
    .and
    .order()
        .hasBasePrice(100.00)
    .run();
```

> Try `.given.spaceship()` -- **compile error**.
> Try `.then` before `.when` -- **compile error**.
> The IDE shows you exactly what's available at every step.

---

## Why Valenty?

The workflow is simple:

```
QA writes scenario in English
    --> AI translates to typed DSL
        --> Compiler validates structure
            --> Tests run
```

### Gherkin vs Valenty

| | Textual Gherkin | Valenty DSL |
|---|---|---|
| **Typo in step** | Runtime failure | Compile error |
| **IDE support** | None | Full autocompletion |
| **Refactor domain** | Find/replace strings everywhere | Rename once, done |
| **Step ordering** | Nothing prevents 2 Whens | Compiler enforces Given->When->Then |
| **AI generation** | AI can invent nonexistent steps | AI can only use existing builder methods |
| **Maintenance at scale** | Painful (string duplication) | Trivial (type-safe refactoring) |

---

## Quick Start

```bash
# 1. Install the CLI
dart pub global activate valenty_cli

# 2. Initialize in your project (adds dependency + AI skills)
cd my_project
valenty init

# 3. Ask your AI to scaffold builders
#    "Scaffold the Order feature builders for acceptance testing"

# 4. Ask your AI to write tests
#    "Write test for: Given a product with unit price $20, when order placed with quantity 5, then base price is $100"

# 5. Run tests
dart test
```

That is it. The CLI installs everything. Your AI tool reads the generated skill files and knows the full DSL architecture, your project's models, and how to generate correct typed code.

---

## Complete AI Setup Guide

Valenty is designed so that AI tools do the actual work. The `valenty init` command detects which AI tools you use and generates instruction files that teach each tool:

1. The complete typed builder architecture (phantom types, builder hierarchy)
2. Code templates for every builder type (Scenario, Given, When, Then, Assertion)
3. Working examples of correct DSL code
4. A snapshot of your project (domain models, existing builders, features)

### Claude Code

```bash
valenty init  # Auto-detects .claude/ directory
```

Generated file: `.claude/skills/valenty-test-writer/SKILL.md`

This skill file gives Claude Code complete knowledge of how to scaffold builders from your domain models and write acceptance tests using the typed DSL. It includes the full builder hierarchy, phantom type constraints, code templates, and a live snapshot of your project's current state (models, features, existing builders).

### Cursor

```bash
valenty init  # Auto-detects .cursor/ directory
```

Generated file: `.cursor/rules/valenty.mdc`

The rule file is loaded automatically by Cursor and provides the same complete DSL knowledge as the Claude skill.

### Codex

```bash
valenty init  # Always generates AGENTS.md
```

Generated file: `AGENTS.md`

This file is always generated regardless of which AI tools are detected, since it serves as a portable instruction format.

### OpenCode

```bash
valenty init  # Auto-detects .opencode/ directory
```

Generated file: `.opencode/agents/valenty-test-writer.md`

### Refreshing AI Context

After you add new builders, new features, or update Valenty itself, regenerate the skill files so your AI tool sees the latest project state:

```bash
valenty generate skills
```

This re-introspects your project (scans `test/valenty/features/` for builders and `lib/` for domain models) and updates all detected AI tool files with the current snapshot.

---

## The AI Workflow

```
PHASE 1: Setup
  valenty init
      |-- Adds valenty_dsl as dev dependency
      |-- Creates .valenty.yaml configuration
      |-- Generates AI skill files for detected tools

PHASE 2: Scaffold (AI does this)
  Tell your AI: "Scaffold the Payment feature"
      |-- AI reads your domain models in lib/
      |-- AI generates the full builder tree:
          Scenario, GivenBuilder, DomainObjectBuilders,
          WhenBuilder, ActionBuilder, ThenBuilder, AssertionBuilders

PHASE 3: Refresh context
  valenty generate skills
      |-- Updates AI skill files with new builders
      |-- AI now knows about the new feature

PHASE 4: Write tests (AI does this)
  Tell your AI: "Write test: Given a payment of $50..."
      |-- AI reads existing builders
      |-- AI generates typed DSL code using only real methods
      |-- Compiler validates the result

PHASE 5: Iterate
  Rename builders or methods in one place
      |-- Compiler catches all broken tests
      |-- Fix in one place, all tests update
```

### Adding a New Domain Concept

When you need a new concept (e.g., "shipping address"):

1. Ask your AI: "Add an AddressGivenBuilder to the Order feature"
2. The AI reads existing builders and creates the new one following the pattern
3. Regenerate AI skills:

```bash
valenty generate skills
```

4. Now you (or AI) can write:

```dart
OrderScenario('should use shipping address')
    .given
    .product().withUnitPrice(20.00)
    .and
    .address()
        .withCity('New York')
        .withZipCode('10001')
    .when
    .placeOrder().withQuantity(1)
    .then
    .shouldSucceed()
    .run();
```

### Adding a New Feature

Ask your AI: "Scaffold the Payment feature builders for acceptance testing"

The AI reads your `lib/` code, finds the Payment domain models, and generates the complete builder tree. Then run `valenty generate skills` so the AI knows about the new feature for future test writing.

---

## CLI Commands

| Command | What it does |
|---------|-------------|
| `valenty init` | Full setup: add DSL dependency, create config, install AI skills |
| `valenty generate skills` | (Re)generate AI skill files after updating builders or Valenty |
| `valenty scaffold feature <name> --models <paths>` | Generate builder tree from model files |
| `valenty list features` | List all scaffolded features and their builders |
| `valenty list builders [--feature X] [--phase given]` | List builders with filtering by feature or phase |
| `valenty context [--format json\|yaml]` | Output full project state for AI consumption |
| `valenty validate [--feature X]` | Validate builder files for correctness and conventions |
| `valenty test [--feature X] [--scenario "name"]` | Run Valenty acceptance tests (wraps dart/flutter test) |
| `valenty doctor` | Check environment readiness |
| `valenty update` | Self-update the CLI |

### Command Details

**`valenty scaffold feature`** -- Reads Dart model files and generates the full builder tree for a feature. Accepts comma-separated model paths:

```bash
valenty scaffold feature order --models lib/models/order.dart,lib/models/product.dart
```

**`valenty list builders`** -- Introspects the project and lists every builder with its methods and return types. Filter by feature or phase:

```bash
valenty list builders --feature order --phase given
```

**`valenty context`** -- Outputs structured YAML or JSON describing every feature, builder, and method. Useful for piping into AI tools or debugging:

```bash
valenty context --format json
```

**`valenty validate`** -- Checks builder files for structural correctness (missing scenario class, orphaned builders, naming convention violations):

```bash
valenty validate --feature order
```

**`valenty test`** -- Wraps `dart test` or `flutter test` with Valenty-specific targeting. Supports feature filtering, scenario name patterns, reporter selection, and coverage:

```bash
valenty test --feature order --scenario "base price" --reporter expanded
valenty test --coverage
```

---

## DSL Builder Hierarchy

The type system enforces the Given -> When -> Then flow at compile time using phantom types:

```
FeatureScenario
    |
    v
.given --> GivenBuilder --> DomainObjectBuilder<NeedsWhen>
                                |
                                | .withField(), .and
                                |
                                v
           .when  --> WhenBuilder --> ActionBuilder<NeedsThen>
                                          |
                                          | .withParam()
                                          |
                                          v
                      .then --> ThenBuilder --> AssertionBuilder
                                                    |
                                                    | .hasField(), .shouldSucceed()
                                                    |
                                                    v
                                              .run() --> ScenarioRunner
```

Each arrow represents a type transition. You cannot call `.when` from a `ThenBuilder` or `.then` from a `GivenBuilder` -- the compiler rejects it. The phantom type parameters (`NeedsWhen`, `NeedsThen`) encode the state machine into the type system.

### Builder File Structure

When AI scaffolds a feature, it generates this structure:

```
test/valenty/features/<feature>/
+-- <feature>_scenario.dart              # Entry point: FeatureScenario('...')
+-- builders/
|   +-- given/
|   |   +-- <feature>_given_builder.dart # .given.product(), .given.coupon()
|   |   +-- product_given_builder.dart   # .withUnitPrice(), .withName()
|   |   +-- coupon_given_builder.dart    # .withDiscount(), .withCode()
|   +-- when/
|   |   +-- <feature>_when_builder.dart  # .when.placeOrder()
|   |   +-- place_order_when_builder.dart # .withQuantity()
|   +-- then/
|       +-- <feature>_then_builder.dart   # .then.shouldSucceed(), .then.order()
|       +-- order_assertion_builder.dart  # .hasBasePrice(), .hasQuantity()
+-- scenarios/
    +-- (test files go here)
```

---

## Architecture

```
valenty_dsl (library -- add as dev_dependency)
    +-- Core: phantom types, ScenarioBuilder, TestContext
    +-- Builders: GivenBuilder, WhenBuilder, ThenBuilder,
    |            DomainObjectBuilder, AssertionBuilder
    +-- Runner: ScenarioRunner (executes scenarios as package:test tests)
    +-- Channels: UI, API, CLI (for multi-channel testing)
    +-- Fixtures: FixtureBase, TestDataBuilder, CreationMethods
    +-- Matchers: hasField, satisfiesAll, expectDelta
    +-- Helpers: parameterizedTest, guardAssertion

valenty_cli (CLI tool -- install globally)
    +-- init: project setup + AI skill generation
    +-- generate: AI tool skill files
    +-- scaffold: builder tree generation from models
    +-- list: feature and builder introspection
    +-- context: structured project state output
    +-- validate: builder correctness checking
    +-- test: acceptance test runner
    +-- doctor: environment check
    +-- update: self-update
```

---

## Example

See the [`examples/order_pricing/`](examples/order_pricing/) directory for a complete working project with:
- Domain models (`Product`, `Order`)
- Full builder tree for the Order feature
- 3 QA scenarios translated to typed DSL tests
- All tests passing

```bash
cd examples/order_pricing
dart pub get
dart test --reporter expanded
```

---

## Packages

| Package | Description | Status |
|---------|-------------|--------|
| `valenty_cli` | CLI tool -- installs DSL dependency and AI skills | 0.1.0 - Pre-release |
| `valenty_dsl` | DSL library -- phantom types, builders, matchers | 0.1.0 - Pre-release |

---

## License

MIT
