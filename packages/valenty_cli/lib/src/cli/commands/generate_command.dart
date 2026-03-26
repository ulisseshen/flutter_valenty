import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../detection/ai_tool_detector.dart';
import '../../generators/ai_tools/claude/claude_skill_generator.dart';
import '../../generators/ai_tools/codex/codex_agent_generator.dart';
import '../../generators/ai_tools/cursor/cursor_rule_generator.dart';
import '../../generators/ai_tools/opencode/opencode_agent_generator.dart';
import '../../models/ai_tool_type.dart';

class GenerateCommand extends Command<void> {
  GenerateCommand({required Logger logger}) : _logger = logger {
    addSubcommand(_SkillsSubCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate AI tool skills and configurations.';
}

class _SkillsSubCommand extends Command<void> {
  _SkillsSubCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'skills';

  @override
  String get description =>
      'Generate AI tool skill files for detected tools.';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final detecting = _logger.progress('Detecting AI tools');
    final detector = AiToolDetector();
    final tools = detector.detect(projectPath);

    if (tools.isEmpty) {
      detecting.complete('No AI tools detected');
      _logger.info(
        'No AI tool directories found. Will generate AGENTS.md '
        'and Claude skill (recommended defaults).',
      );
      // Generate defaults even if no tool directories are detected
      await _generateForTool(AiToolType.claude, projectPath);
      await _generateAgentsMd(projectPath);
      _logger.success('Generated default skill files.');
      return;
    }

    detecting.complete(
      'Detected ${tools.length} AI tool(s): '
      '${tools.map((t) => t.displayName).join(', ')}',
    );

    for (final tool in tools) {
      await _generateForTool(tool, projectPath);
    }

    // Always generate AGENTS.md (portable, works with Codex and OpenCode)
    await _generateAgentsMd(projectPath);

    _logger.success(
      'Skill generation complete. '
      '${tools.length + 1} file(s) generated.',
    );
  }

  Future<void> _generateForTool(AiToolType tool, String projectPath) async {
    switch (tool) {
      case AiToolType.claude:
        await ClaudeSkillGenerator(logger: _logger).generate(projectPath);
      case AiToolType.cursor:
        await CursorRuleGenerator(logger: _logger).generate(projectPath);
      case AiToolType.codex:
        // AGENTS.md is generated separately (always)
        break;
      case AiToolType.openCode:
        await OpenCodeAgentGenerator(logger: _logger).generate(projectPath);
    }
  }

  Future<void> _generateAgentsMd(String projectPath) async {
    await CodexAgentGenerator(logger: _logger).generate(projectPath);
  }
}
