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
  ///
  /// If [isFlutter] is true, a header comment is added indicating
  /// valentyTest is the primary approach for this project.
  Future<void> generate(
    String projectPath, {
    ProjectSnapshot? snapshot,
    bool isFlutter = false,
  }) async {
    final skillDir = Directory(
      p.join(projectPath, '.claude', 'skills', 'valenty-test-writer'),
    );

    if (!skillDir.existsSync()) {
      skillDir.createSync(recursive: true);
    }

    final projectTypeHeader = _buildProjectTypeHeader(isFlutter);
    final content = projectTypeHeader +
        valentySkillTemplate +
        renderProjectSnapshotSection(snapshot, isFlutter: isFlutter);

    final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
    skillFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Claude skill: '
      '.claude/skills/valenty-test-writer/SKILL.md',
    );

    // Generate first-tests skill (post-init guide)
    final firstTestsDir = Directory(
      p.join(projectPath, '.claude', 'skills', 'valenty-onboarding'),
    );

    if (!firstTestsDir.existsSync()) {
      firstTestsDir.createSync(recursive: true);
    }

    final firstTestsFile = File(p.join(firstTestsDir.path, 'SKILL.md'));
    firstTestsFile.writeAsStringSync(valentyInitSkillTemplate);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Claude skill: '
      '.claude/skills/valenty-onboarding/SKILL.md',
    );
  }

  String _buildProjectTypeHeader(bool isFlutter) {
    if (isFlutter) {
      return '# Project type: Flutter\n'
          '# Primary approach: valentyTest (UI-first component testing)\n'
          '# See Part A below for the recommended workflow.\n\n';
    }
    return '# Project type: Dart\n'
        '# Primary approach: Typed builders (compile-time safe DSL)\n'
        '# See Part B below for the recommended workflow.\n\n';
  }
}
