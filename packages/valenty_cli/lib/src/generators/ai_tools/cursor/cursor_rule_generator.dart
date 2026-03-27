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
  }) async {
    final rulesDir = Directory(
      p.join(projectPath, '.cursor', 'rules'),
    );

    if (!rulesDir.existsSync()) {
      rulesDir.createSync(recursive: true);
    }

    final content = cursorRuleTemplate +
        renderProjectSnapshotSection(snapshot);

    final ruleFile = File(p.join(rulesDir.path, 'valenty.mdc'));
    ruleFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Cursor rule: '
      '.cursor/rules/valenty.mdc',
    );
  }
}
