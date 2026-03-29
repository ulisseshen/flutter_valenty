# Changelog

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
