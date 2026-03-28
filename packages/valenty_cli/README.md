# valenty_cli

AI-powered component test generation CLI for Flutter apps with compile-time safety.

Part of the [Valenty](https://github.com/valenty-dev/valenty) testing framework.

## Installation

```bash
dart pub global activate valenty_cli
```

## Quick Start

```bash
# Initialize in your Flutter project
cd my_flutter_app
valenty init

# Ask your AI to scaffold tests
# "Scaffold the Order feature for valentyTest"

# Regenerate AI skills after changes
valenty generate skills
```

## Commands

| Command | Description |
|---------|-------------|
| `valenty init` | Full setup: add dependency, create config, install AI skills |
| `valenty generate skills` | Regenerate AI skill files after updating builders |
| `valenty scaffold feature <name> --models <paths>` | Generate builder tree from models |
| `valenty list features` | List all scaffolded features |
| `valenty list builders` | List builders with filtering |
| `valenty context` | Output project state as YAML/JSON for AI |
| `valenty validate` | Validate builder correctness |
| `valenty test` | Run Valenty tests (wraps dart/flutter test) |
| `valenty doctor` | Check environment readiness |
| `valenty update` | Self-update the CLI |

## AI Tool Support

Generates skill/rule files for:
- **Claude Code** — `.claude/skills/valenty-test-writer/SKILL.md`
- **Cursor** — `.cursor/rules/valenty.mdc`
- **Codex** — `AGENTS.md`
- **OpenCode** — `.opencode/agents/valenty-test-writer.md`

## Documentation

See the [full documentation](https://github.com/valenty-dev/valenty) for the complete guide.

## License

MIT
