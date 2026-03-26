# Valenty

**Compile-time safe acceptance testing for Dart & Flutter.**

Valenty replaces fragile string-based Gherkin with a typed fluent DSL where **the compiler catches errors before you run any test**. No `.feature` files, no glue code, no runtime surprises.

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

## Packages

| Package | Description | Status |
|---------|-------------|--------|
| `valenty_cli` | CLI tool -- installs DSL dependency and AI skills | In development |
| `valenty_dsl` | DSL library -- phantom types, builders, matchers | In development |

---

## Quick Start

### 1. Install the CLI

```bash
dart pub global activate valenty_cli
```

### 2. Initialize in your project

```bash
cd my_flutter_app
valenty init
```

This will:
- Detect your project type (Flutter app, Dart package, etc.)
- Add `valenty_dsl` as a dev dependency
- Create `.valenty.yaml` configuration
- Detect your AI tools (Claude Code, Cursor, Codex, OpenCode)
- Generate AI skill files so your AI assistant knows how to scaffold builders and write tests

### 3. Ask your AI to scaffold builders

Tell your AI assistant:

> "Scaffold the Order feature builders for acceptance testing"

The AI reads your domain models in `lib/` and generates the full builder tree:

```
test/valenty/features/order/
+-- order_scenario.dart              # Entry point: OrderScenario('...')
+-- builders/
|   +-- given/
|   |   +-- order_given_builder.dart  # .given.product(), .given.coupon()
|   |   +-- product_given_builder.dart # .withUnitPrice(), .withName()
|   |   +-- coupon_given_builder.dart  # .withDiscount(), .withCode()
|   +-- when/
|   |   +-- order_when_builder.dart    # .when.placeOrder()
|   |   +-- place_order_when_builder.dart # .withQuantity()
|   +-- then/
|       +-- order_then_builder.dart     # .then.shouldSucceed(), .then.order()
|       +-- order_assertion_builder.dart # .hasBasePrice(), .hasQuantity()
+-- scenarios/
    +-- (your test files go here)
```

### 4. Ask your AI to write tests

Give a QA scenario to your AI tool:

> "Write tests for: Given a product with unit price $20 and a coupon with 10% discount,
> when an order is placed with quantity 5, then the base price should be $90"

The AI reads your builders and generates:

```dart
OrderScenario('should apply percentage coupon to base price')
    .given
    .product()
        .withUnitPrice(20.00)
    .and
    .coupon()
        .withDiscount(0.10)
    .when
    .placeOrder()
        .withQuantity(5)
    .then
    .order()
        .hasBasePrice(90.00)
    .run();
```

Because the DSL is typed, the AI **cannot invent methods that don't exist**. If it tries, the compiler catches it.

---

## How It Works

The key insight: **the CLI is just an installer**. The AI does the heavy lifting.

```
valenty init
    |
    +-- Adds valenty_dsl dependency
    +-- Installs AI skill files that teach your AI tool:
        1. How to read your domain models
        2. How to scaffold typed fluent DSL builders
        3. How to write acceptance tests from QA scenarios
```

The AI skill files contain the complete DSL architecture, code templates for every
builder type, and rules for generating correct code. Your AI tool uses these to
understand the typed builder pattern and generate compile-time safe code.

---

## Day-to-Day Workflow

### The typical cycle

```
QA writes scenario in English
        |
        v
AI translates to typed DSL (reads builders, maps scenario)
        |
        v
Compiler validates -- wrong order? compile error.
Missing method? compile error. Typo? compile error.
        |
        v
Run tests -- if it compiles, the structure is correct.
Only business logic assertions can fail.
        |
        v
Refactor freely -- rename product() to item()
in one place, all 200 tests update automatically.
```

### Adding a new domain concept

When you need to add a new concept (e.g., "shipping address"):

1. Ask your AI: "Add an AddressGivenBuilder to the Order feature"
2. The AI reads existing builders and creates the new one
3. Regenerate AI skills (so AI knows about the new builder):

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

### Adding a new feature

Ask your AI: "Scaffold the Payment feature builders for acceptance testing"

The AI reads your `lib/` code, finds the Payment domain models, and generates
the complete builder tree.

---

## CLI Commands

| Command | What it does |
|---------|-------------|
| `valenty init` | Full setup: add DSL dependency, create config, install AI skills |
| `valenty generate skills` | (Re)generate AI skill files (after updating builders or valenty) |
| `valenty doctor` | Check environment readiness |
| `valenty update` | Self-update the CLI |

---

## Why Typed DSL Over Textual Gherkin?

| | Textual Gherkin | Valenty DSL |
|---|---|---|
| **Typo in step** | Runtime failure | Compile error |
| **IDE support** | None | Full autocompletion |
| **Refactor domain** | Find/replace strings everywhere | Rename once, done |
| **Step ordering** | Nothing prevents 2 Whens | Compiler enforces Given->When->Then |
| **AI generation** | AI can invent nonexistent steps | AI can only use existing builder methods |
| **Maintenance at scale** | Painful (string duplication) | Trivial (type-safe refactoring) |

---

## AI Tool Integration

Valenty generates skill/rule/agent files for your AI tools:

| AI Tool | Generated Files |
|---------|----------------|
| **Claude Code** | `.claude/skills/valenty-test-writer/SKILL.md` |
| **Cursor** | `.cursor/rules/valenty.mdc` |
| **Codex / OpenCode** | `AGENTS.md` |
| **OpenCode** | `.opencode/agents/valenty-test-writer.md` |

These files teach the AI tool:
1. The complete typed builder architecture
2. How to scaffold builders from domain models
3. How to map English scenarios to typed DSL code
4. The compile-time safety rules

Run `valenty generate skills` after updating Valenty to refresh the skill files.

---

## Architecture

```
valenty_dsl (library -- add as dev_dependency)
+-- Core: phantom types, ScenarioBuilder, TestContext
+-- Builders: GivenBuilder, WhenBuilder, ThenBuilder, DomainObjectBuilder, AssertionBuilder
+-- Runner: ScenarioRunner (executes scenarios as package:test tests)
+-- Channels: UI, API, CLI (for multi-channel testing)
+-- Fixtures: FixtureBase, TestDataBuilder, CreationMethods
+-- Matchers: hasField, satisfiesAll, expectDelta
+-- Helpers: parameterizedTest, guardAssertion

valenty_cli (CLI tool -- install globally)
+-- init: project setup + AI skill generation
+-- generate: AI tool skill files
+-- doctor: environment check
+-- update: self-update
```

---

## Example

See the [`example/`](example/) directory for a complete working project with:
- Domain models (`Product`, `Order`)
- Full builder tree for the Order feature
- 3 QA scenarios translated to typed DSL tests
- All tests passing

```bash
cd example
dart pub get
dart test --reporter expanded
```

---

## License

MIT
