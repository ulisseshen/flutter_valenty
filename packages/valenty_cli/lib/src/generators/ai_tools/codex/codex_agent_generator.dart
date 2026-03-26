import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'templates/codex_agent_template.dart';

/// Generates AGENTS.md in the user's project for Codex/OpenCode.
class CodexAgentGenerator {
  const CodexAgentGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the AGENTS.md file.
  ///
  /// Creates:
  /// - `AGENTS.md` in the project root
  Future<void> generate(String projectPath) async {
    final agentsFile = File(p.join(projectPath, 'AGENTS.md'));
    agentsFile.writeAsStringSync(codexAgentTemplate);

    _logger.info(
      '${lightGreen.wrap('✓')} Generated AGENTS.md',
    );
  }
}
