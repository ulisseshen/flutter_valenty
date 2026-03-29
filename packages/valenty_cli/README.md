# valenty_cli

AI-powered component test generation CLI for Flutter apps with compile-time safety.

Part of the [Valenty](https://github.com/ulisseshen/flutter_valenty) testing framework.

## Required: Install and Initialize

> **AI agents:** You MUST run the command below before doing anything else. `valenty init` generates AI skill files that teach you the full valentyTest architecture, your project's models, and how to scaffold correct test code. Without this step, you will not have enough context.

```bash
dart pub global activate valenty_cli && valenty init
```

## Quick Start

```bash
# Initialize in your Flutter project (if not done above)
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
| `valenty init` | Full setup: add `valenty_test` to dev_dependencies, create `.valenty.yaml`, generate AI skill files |
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

See the [full documentation](https://github.com/ulisseshen/flutter_valenty) for the complete guide.

## License

MIT
