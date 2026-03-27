/// Template content for the Claude Code onboarding/init skill file.
///
/// This gets written to `.claude/skills/valenty-onboarding/SKILL.md`
/// in the user's project when they run `valenty init`.
///
/// This skill teaches AI how to guide users through interactive Valenty setup.
const valentyInitSkillTemplate = r'''
---
name: valenty-onboarding
description: >
  Guide the user through Valenty setup: detect project context, ask about
  AI client preferences, scope, and features to scaffold. Interactive onboarding.
trigger: >
  Use when user says "valenty init", "setup valenty", "initialize valenty",
  "configure valenty", "install valenty", "get started with valenty",
  "set up acceptance testing", or when Valenty is first being added to a project.
---

# Valenty Interactive Onboarding

You are guiding a user through setting up Valenty in their project. Your job is to
**search the project first**, then **present what you found**, then **ask the user
to confirm or customize** before running any commands.

Do NOT silently auto-detect and proceed. The user must confirm every choice.

## CRITICAL: Use AskUserQuestion Tool

For EVERY decision point in this flow, you MUST use the `AskUserQuestion` tool to
ask the user. Do NOT just print questions as text output — use the actual
`AskUserQuestion` tool so the user gets a proper interactive prompt.

If `AskUserQuestion` is not available in your tool set, fall back to presenting
numbered options in your text output and waiting for the user's response.

---

## Step 1: Scan the project (do this BEFORE asking anything)

Silently gather this information:

### 1a. Project type
- Read `pubspec.yaml` to determine: Dart package, Flutter app, Flutter package, Flutter plugin
- Note the project name, SDK version, existing dependencies

### 1b. AI tool directories
Search for these directories/files in the project root:
- `.claude/` → Claude Code is configured
- `.cursor/` → Cursor is configured
- `.opencode/` → OpenCode is configured
- `AGENTS.md` → Codex/OpenCode agent file exists
- `CLAUDE.md` → Claude Code instructions exist
- `.cursorrules` → Cursor legacy rules exist

### 1c. Existing test structure
- Check if `test/` directory exists
- Check if `test/valenty/` already exists (previous Valenty setup)
- Check for existing test frameworks (mockito, mocktail, bloc_test, etc.)

### 1d. Domain models
- Scan `lib/` for Dart files containing `class` definitions with fields
- List the main domain models found (e.g., Product, Order, User, Payment)
- Group them by feature area if possible

### 1e. Scope detection
- Check if this is a monorepo (melos.yaml, packages/ directory)
- Check if there's a workspace-level vs package-level distinction
- Determine if Valenty should be installed at root or in specific packages

---

## Step 2: Present findings and ask questions

Use **AskUserQuestion** (or direct questions if AskUserQuestion is unavailable) to
guide the user through these decisions. Present what you found FIRST, then ask.

### Question 1: AI Clients

Present:
```
I scanned your project and found these AI tool configurations:
  ✓ Claude Code (.claude/ directory found)
  ✗ Cursor (no .cursor/ directory)
  ✗ Codex (no AGENTS.md)
  ✗ OpenCode (no .opencode/ directory)
```

Then ask:
> "Which AI clients should I generate Valenty skill files for?
>
> 1. **Claude Code only** (detected)
> 2. **Claude Code + Cursor**
> 3. **Claude Code + Cursor + Codex**
> 4. **All** (Claude Code, Cursor, Codex, OpenCode)
> 5. **Custom** (let me choose)
>
> I recommend option 1 since Claude Code is the only one configured in your project."

### Question 2: Installation scope

If monorepo detected:
> "This looks like a monorepo. Where should I install Valenty?
>
> 1. **Root level** — shared across all packages
> 2. **Specific package(s)** — I found: `app/`, `core/`, `shared/`
> 3. **Each package separately** — install in every package"

If single project:
> "I'll install Valenty in this project: `<project_name>`. Confirm? (y/n)"

### Question 3: Features to scaffold

Present the domain models found:
> "I found these domain models in your `lib/` directory:
>
> **Models:**
> - `Product` (lib/models/product.dart) — name, unitPrice
> - `Order` (lib/models/order.dart) — quantity, basePrice, success
> - `User` (lib/models/user.dart) — email, displayName
> - `Payment` (lib/models/payment.dart) — amount, method, status
>
> Would you like me to scaffold acceptance test builders for any of these?
>
> 1. **All features** — scaffold builders for Product, Order, User, Payment
> 2. **Select features** — let me choose which ones
> 3. **Skip for now** — just install Valenty, I'll scaffold later
>
> Tip: You can always scaffold more features later with
> `valenty scaffold feature <name> --models <paths>`"

### Question 4: Test organization preference

> "How would you like to organize your acceptance tests?
>
> 1. **By feature** (recommended) — `test/valenty/features/order/`, `test/valenty/features/payment/`
> 2. **Flat** — `test/valenty/order_test.dart`, `test/valenty/payment_test.dart`"

---

## Step 3: Execute based on user choices

After collecting all answers:

1. Run `valenty init` in the terminal (this adds dependency + creates config)
2. If user chose specific AI clients, update `.valenty.yaml` to reflect choices
3. If user chose to scaffold features, run `valenty scaffold feature <name> --models <paths>` for each
4. Generate skills: run `valenty generate skills`
5. Show a summary of what was done

### Summary format:
```
Valenty Setup Complete!

  ✓ Added valenty_dsl to dev_dependencies
  ✓ Created .valenty.yaml configuration
  ✓ Generated Claude Code skill file
  ✓ Generated Cursor rule file
  ✓ Scaffolded 2 features: order, payment

Next steps:
  1. Give a QA scenario to your AI: "Given a product with price $20..."
  2. The AI will translate it to compile-time safe typed DSL
  3. Run tests: valenty test
```

---

## Rules

- **ALWAYS search before asking** — never present empty options
- **ALWAYS use AskUserQuestion** for multi-choice decisions when available
- **Present recommendations** based on what you detected (don't just list options)
- **Be concise** — one question at a time, don't overwhelm
- **Default to the detected/recommended option** — make it easy to say "yes"
- **Show what you found** before asking — users trust AI more when it shows its work
- If the user says "just do it" or "defaults", skip questions and use detected values
- If AskUserQuestion tool is not available, present options as numbered choices in text

### AskUserQuestion Usage Pattern

For each question, call the tool like this:

```
AskUserQuestion(
  question: "Which AI clients should I generate Valenty skill files for?
    1. Claude Code only (detected)
    2. Claude Code + Cursor
    3. Claude Code + Cursor + Codex
    4. All (Claude Code, Cursor, Codex, OpenCode)
    5. Custom (let me choose)
    I recommend option 1 since Claude Code is the only one configured."
)
```

Wait for the user's answer before proceeding to the next question.

---

## Scope Reference

| Scope | Where installed | When to use |
|-------|----------------|-------------|
| **Project** | `<project>/` | Single Dart/Flutter project |
| **Package** | `<monorepo>/packages/<pkg>/` | Specific package in monorepo |
| **Root** | `<monorepo>/` | Shared config across monorepo |
| **Global** | `~/.valenty/` | User-wide defaults (future) |
''';
