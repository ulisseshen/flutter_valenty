import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'templates/cursor_rule_template.dart';

/// Generates Cursor MDC rule files in the user's project.
class CursorRuleGenerator {
  const CursorRuleGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the Valenty rule for Cursor.
  ///
  /// Creates:
  /// - `.cursor/rules/valenty.mdc`
  Future<void> generate(String projectPath) async {
    final rulesDir = Directory(
      p.join(projectPath, '.cursor', 'rules'),
    );

    if (!rulesDir.existsSync()) {
      rulesDir.createSync(recursive: true);
    }

    final ruleFile = File(p.join(rulesDir.path, 'valenty.mdc'));
    ruleFile.writeAsStringSync(cursorRuleTemplate);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated Cursor rule: '
      '.cursor/rules/valenty.mdc',
    );
  }
}
