import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../../analyzers/project_introspector.dart';
import '../project_snapshot_section.dart';
import 'templates/valenty_init_skill_template.dart';
import 'templates/valenty_skill_template.dart';

/// Generates Claude Code skill files in the user's project.
class ClaudeSkillGenerator {
  const ClaudeSkillGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the Valenty skill for Claude Code.
  ///
  /// Creates:
  /// - `.claude/skills/valenty-test-writer/SKILL.md`
  ///
  /// If [snapshot] is provided, appends a dynamic "Current Project State"
  /// section with discovered features, builders, and domain models.
  Future<void> generate(
    String projectPath, {
    ProjectSnapshot? snapshot,
  }) async {
    final skillDir = Directory(
      p.join(projectPath, '.claude', 'skills', 'valenty-test-writer'),
    );

    if (!skillDir.existsSync()) {
      skillDir.createSync(recursive: true);
    }

    final content = valentySkillTemplate +
        renderProjectSnapshotSection(snapshot);

    final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
    skillFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Claude skill: '
      '.claude/skills/valenty-test-writer/SKILL.md',
    );

    // Generate onboarding skill
    final onboardingDir = Directory(
      p.join(projectPath, '.claude', 'skills', 'valenty-onboarding'),
    );

    if (!onboardingDir.existsSync()) {
      onboardingDir.createSync(recursive: true);
    }

    final onboardingFile = File(p.join(onboardingDir.path, 'SKILL.md'));
    onboardingFile.writeAsStringSync(valentyInitSkillTemplate);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Claude skill: '
      '.claude/skills/valenty-onboarding/SKILL.md',
    );
  }
}
