import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'templates/valenty_skill_template.dart';

/// Generates Claude Code skill files in the user's project.
class ClaudeSkillGenerator {
  const ClaudeSkillGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the Valenty skill for Claude Code.
  ///
  /// Creates:
  /// - `.claude/skills/valenty-test-writer/SKILL.md`
  Future<void> generate(String projectPath) async {
    final skillDir = Directory(
      p.join(projectPath, '.claude', 'skills', 'valenty-test-writer'),
    );

    if (!skillDir.existsSync()) {
      skillDir.createSync(recursive: true);
    }

    final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
    skillFile.writeAsStringSync(valentySkillTemplate);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Claude skill: '
      '.claude/skills/valenty-test-writer/SKILL.md',
    );
  }
}
