import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../../analyzers/project_introspector.dart';
import '../project_snapshot_section.dart';
import 'templates/codex_agent_template.dart';

/// Generates AGENTS.md in the user's project for Codex/OpenCode.
class CodexAgentGenerator {
  const CodexAgentGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the AGENTS.md file.
  ///
  /// Creates:
  /// - `AGENTS.md` in the project root
  ///
  /// If [snapshot] is provided, appends a dynamic "Current Project State"
  /// section with discovered features, builders, and domain models.
  Future<void> generate(
    String projectPath, {
    ProjectSnapshot? snapshot,
  }) async {
    final content = codexAgentTemplate +
        renderProjectSnapshotSection(snapshot);

    final agentsFile = File(p.join(projectPath, 'AGENTS.md'));
    agentsFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated AGENTS.md',
    );
  }
}
