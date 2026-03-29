# Changelog

## 0.3.4

- Stronger AI agent instructions in scope prompt: "STOP HERE. DO NOT CONTINUE."
- AI agents now reliably use AskUserQuestion before proceeding

## 0.3.3

- Fix: replace interactive chooseOne with non-interactive [ACTION REQUIRED] output
- AI reads the output and uses AskUserQuestion to ask the user
- Add --scope=project|user flag to valenty init
- Default to --scope=project when no flag provided

## 0.3.2

- Simplify skill scope prompt: "This project only" vs "All my projects (recommended)"

## 0.3.1

- Fix skill install scope: project (git root) vs user (~/) instead of git root vs project subdir
- User scope installs to ~/.claude/skills/ — skills available across ALL projects

## 0.3.0

- Monorepo support: detect git root and ask where to install AI skill files
- Skills are now installed at git root by default (where Claude Code, Cursor, Codex look)
- Interactive prompt when running from a subdirectory of a git repo

## 0.2.0

- Replace `valenty-onboarding` skill with `valenty-first-tests` — guides AI to scan project and generate first test scenarios after init
- Fix: `valenty init` now adds `valenty_test: ^0.2.1` (was ^0.1.0)
- Improved init success message: single clear next step instead of multiple options

## 0.1.2

- Clarify that `valenty init` adds `valenty_test` to dev_dependencies

## 0.1.1

- Add mandatory AI setup instructions to README
- Fix repository and homepage URLs

## 0.1.0

- Initial release
- `valenty init` command with project detection and AI skill generation
- `valenty generate skills` for AI tool skill files (Claude, Cursor, Codex, OpenCode)
- `valenty scaffold feature` for builder generation from models
- `valenty list` for feature and builder introspection
- `valenty context` for AI-consumable project state (YAML/JSON)
- `valenty validate` for builder correctness checking
- `valenty test` for running Valenty acceptance tests
- `valenty doctor` and `valenty update` commands
