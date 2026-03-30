# Valenty Plugin Plan

## Goal

One `npx` command installs Valenty as a plugin across all AI coding tools.

```bash
npx valenty-tester@latest
```

## Research Summary

| Platform | Commands | Skills (auto-trigger) | Rules | User Scope | Project Scope |
|----------|----------|----------------------|-------|------------|---------------|
| **Claude Code** | `~/.claude/commands/valenty/*.md` → `/valenty:test` | `.claude/skills/*/SKILL.md` | `CLAUDE.md` | `~/.claude/commands/` | `<project>/.claude/commands/` |
| **Antigravity** | `.agent/workflows/*.md` → `/valenty-test` | `.agent/skills/*/SKILL.md` | `GEMINI.md` + `AGENTS.md` | `~/.gemini/antigravity/global_workflows/` | `.agent/workflows/` |
| **Cursor** | `.cursor/commands/*.md` → `/valenty-test` | `.cursor/skills/*/SKILL.md` | `.cursor/rules/*.mdc` | `~/.cursor/commands/` | `.cursor/commands/` |
| **Codex** | N/A (no slash commands) | N/A | `AGENTS.md` | N/A | `AGENTS.md` at project root |

### Key Constraints

- **Antigravity**: 12,000 char limit on workflows, no `$ARGUMENTS`, no cross-referencing between files
- **Cursor**: No namespace support (flat `/valenty-test` not `/valenty:test`)
- **Codex**: No slash commands, only reads `AGENTS.md`
- **Claude Code**: Full featured — namespaces, `$ARGUMENTS`, `@/path` references, `allowed-tools`

## Architecture

### npm Package Structure

```
valenty-tester/
├── package.json
├── bin/
│   └── install.mjs              # Main installer script
├── templates/
│   ├── claude/
│   │   ├── commands/
│   │   │   └── valenty/
│   │   │       ├── test.md      # /valenty:test
│   │   │       ├── init.md # /valenty:init
│   │   │       ├── review.md    # /valenty:review
│   │   │       └── help.md      # /valenty:help
│   │   └── workflows/           # Referenced by commands via @path
│   │       ├── test-writer.md
│   │       ├── init.md
│   │       └── review.md
│   ├── antigravity/
│   │   ├── workflows/
│   │   │   ├── valenty-test.md
│   │   │   ├── valenty-init.md
│   │   │   ├── valenty-review.md
│   │   │   └── valenty-help.md
│   │   └── skills/
│   │       └── valenty-test/
│   │           └── SKILL.md
│   ├── cursor/
│   │   ├── commands/
│   │   │   ├── valenty-test.md
│   │   │   ├── valenty-init.md
│   │   │   ├── valenty-review.md
│   │   │   └── valenty-help.md
│   │   ├── rules/
│   │   │   └── valenty.mdc
│   │   └── skills/
│   │       └── valenty-test/
│   │           └── SKILL.md
│   └── codex/
│       └── AGENTS.md
├── shared/
│   └── core-instructions.md     # Single source of truth for test-writing knowledge
├── README.md
└── CHANGELOG.md
```

### Installer Logic (`bin/install.mjs`)

```
1. Detect which AI tools are present:
   - ~/.claude/          → Claude Code detected
   - Check if Antigravity installed (which antigravity || which agy)
   - ~/.cursor/          → Cursor detected

2. Ask user (interactive or --all flag):
   "Which AI tools should I install for?"
   - Claude Code (detected) ✓
   - Antigravity
   - Cursor (detected) ✓
   - Codex/OpenCode (AGENTS.md)

3. For each selected tool:
   Claude Code:
     - Copy commands → ~/.claude/commands/valenty/
     - Copy workflows → ~/.claude/valenty/workflows/

   Antigravity:
     - Copy workflows → ~/.gemini/antigravity/global_workflows/  (user scope)
     - Copy skills → ~/.gemini/antigravity/skills/  (user scope)

   Cursor:
     - Copy commands → ~/.cursor/commands/  (user scope)
     - Copy skills → ~/.cursor/skills/valenty-test/  (user scope)

   Codex:
     - Print instructions to add AGENTS.md to project root

4. Print success message with available commands per tool
```

## Commands to Create

### /valenty:test (Claude) / /valenty-test (Cursor/Antigravity)

**Purpose**: Write tests — routes to acceptance or unit based on user input.

**Flow**:
1. AskUserQuestion: what type of test?
2. Present test names for approval
3. Generate code with fixtures, finders, behavioral names
4. Run tests
5. AskUserQuestion: go deeper? (failures, edges, parameterized)
6. Repeat until user satisfied

### /valenty:init (Claude) / /valenty-init (Cursor/Antigravity)

**Purpose**: First-time setup — scan project, generate first tests.

**Flow**:
1. Scan project (models, services, screens)
2. AskUserQuestion: which feature to test first?
3. Generate 4 infrastructure files + scenarios
4. Run tests
5. AskUserQuestion: upgrade to user scope?

### /valenty:review (Claude) / /valenty-review (Cursor/Antigravity)

**Purpose**: Review existing tests for quality.

**Flow**:
1. Scan all test files
2. Check: naming, fragility, coupling, inline data
3. Generate report
4. AskUserQuestion: auto-fix issues?

### /valenty:help (Claude) / /valenty-help (Cursor/Antigravity)

**Purpose**: Show available commands and quick reference.

## Shared Core Instructions

All platform-specific command files reference the same core logic from `shared/core-instructions.md`. Platform-specific wrappers adapt:

- **Claude Code**: Thin commands with `@/path/to/workflows/*.md` references
- **Antigravity**: Self-contained workflows (no cross-referencing, 12K char limit)
- **Cursor**: Plain markdown commands (no frontmatter)
- **Codex**: Full instructions in AGENTS.md

## What Happens to valenty_cli?

**valenty_cli is killed.** The npm package (`valenty-tester`) handles AI tool installation.
Project configuration (adding `valenty_test` dep, creating `.valenty.yaml`) moves to
`/valenty:init` — the AI adds the dep and config directly.

Only two packages exist:
- **valenty_test** (pub.dev) — the Dart test DSL package
- **valenty-tester** (npm) — the plugin installer for AI tools

## Implementation Steps

1. Create npm package scaffold (`valenty-tester/`)
2. Write Claude Code commands (thin wrappers + workflows)
3. Write Antigravity workflows (self-contained, <12K chars)
4. Write Cursor commands + rules + skills
5. Write Codex AGENTS.md template
6. Write installer script
7. Test on each platform
8. Publish to npm
9. Update READMEs on pub.dev to reference `npx valenty-tester`

## Open Questions

1. Should we also publish to Cursor Marketplace?
2. How to handle updates? (`npx valenty-tester@latest`)

## Decided

- ~~Keep valenty_cli or kill it?~~ → **Kill it.** Onboarding command handles project setup.
- ~~Should the npm package also add valenty_test to pubspec?~~ → **No.** `/valenty:init` does this inside the AI.
