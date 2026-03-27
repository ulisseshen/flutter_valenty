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
    bool isFlutter = false,
  }) async {
    final agentsDir = Directory(
      p.join(projectPath, '.opencode', 'agents'),
    );

    if (!agentsDir.existsSync()) {
      agentsDir.createSync(recursive: true);
    }

    final projectTypeHeader = _buildProjectTypeHeader(isFlutter);
    final content = projectTypeHeader +
        openCodeAgentTemplate +
        renderProjectSnapshotSection(snapshot, isFlutter: isFlutter);

    final agentFile = File(p.join(agentsDir.path, 'valenty-test-writer.md'));
    agentFile.writeAsStringSync(content);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated OpenCode agent: '
      '.opencode/agents/valenty-test-writer.md',
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
