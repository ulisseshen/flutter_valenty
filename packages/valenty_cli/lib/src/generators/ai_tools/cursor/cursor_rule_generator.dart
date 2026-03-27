import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../../analyzers/project_introspector.dart';
import '../project_snapshot_section.dart';
import 'templates/cursor_rule_template.dart';

/// Generates Cursor MDC rule files in the user's project.
class CursorRuleGenerator {
  const CursorRuleGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the Valenty rule for Cursor.
  ///
  /// Creates:
  /// - `.cursor/rules/valenty.mdc`
  ///
  /// If [snapshot] is provided, appends a dynamic "Current Project State"
  /// section with discovered features, builders, and domain models.
  Future<void> generate(
    String projectPath, {
    ProjectSnapshot? snapshot,
    bool isFlutter = false,
  }) async {
    final rulesDir = Directory(
      p.join(projectPath, '.cursor', 'rules'),
    );

    if (!rulesDir.existsSync()) {
      rulesDir.createSync(recursive: true);
    }

    final projectTypeHeader = _buildProjectTypeHeader(isFlutter);
    final content = projectTypeHeader +
        cursorRuleTemplate +
        renderProjectSnapshotSection(snapshot, isFlutter: isFlutter);

    final ruleFile = File(p.join(rulesDir.path, 'valenty.mdc'));
    ruleFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Cursor rule: '
      '.cursor/rules/valenty.mdc',
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
