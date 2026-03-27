import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../../analyzers/project_introspector.dart';
import '../project_snapshot_section.dart';
import 'templates/opencode_agent_template.dart';

/// Generates OpenCode agent files in the user's project.
class OpenCodeAgentGenerator {
  const OpenCodeAgentGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the Valenty agent for OpenCode.
  ///
  /// Creates:
  /// - `.opencode/agents/valenty-test-writer.md`
  ///
  /// If [snapshot] is provided, appends a dynamic "Current Project State"
  /// section with discovered features, builders, and domain models.
  Future<void> generate(
    String projectPath, {
    ProjectSnapshot? snapshot,
  }) async {
    final agentsDir = Directory(
      p.join(projectPath, '.opencode', 'agents'),
    );

    if (!agentsDir.existsSync()) {
      agentsDir.createSync(recursive: true);
    }

    final content = openCodeAgentTemplate +
        renderProjectSnapshotSection(snapshot);

    final agentFile = File(p.join(agentsDir.path, 'valenty-test-writer.md'));
    agentFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated OpenCode agent: '
      '.opencode/agents/valenty-test-writer.md',
    );
  }
}
