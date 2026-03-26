import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../../config/valenty_config.dart';
import '../../config/valenty_config_model.dart';
import '../../detection/ai_tool_detector.dart';
import '../../detection/project_detector.dart';
import '../../generators/ai_tools/claude/claude_skill_generator.dart';
import '../../generators/ai_tools/codex/codex_agent_generator.dart';
import '../../generators/ai_tools/cursor/cursor_rule_generator.dart';
import '../../generators/ai_tools/opencode/opencode_agent_generator.dart';
import '../../models/ai_tool_type.dart';

class InitCommand extends Command<void> {
  InitCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize Valenty: add DSL dependency, create config, install AI skills.';

  @override
  Future<void> run() async {
    _logger.info('Initializing Valenty...');
    _logger.info('');

    final projectPath = Directory.current.path;

    // ── Step 1: Check pubspec.yaml ──────────────────────────────────────
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      _logger.err(
        'No pubspec.yaml found in the current directory.\n'
        'Run this command from the root of a Dart or Flutter project.',
      );
      return;
    }

    // ── Step 2: Detect project type ─────────────────────────────────────
    final detecting = _logger.progress('Detecting project type');
    final ProjectDetector detector;
    try {
      detector = ProjectDetector();
      final projectInfo = await detector.detect(projectPath);
      detecting.complete(
        'Detected: ${projectInfo.type.name} (${projectInfo.name})',
      );

      // ── Step 3: Detect AI tools ─────────────────────────────────────
      final aiDetecting = _logger.progress('Detecting AI tools');
      final aiDetector = AiToolDetector();
      final tools = aiDetector.detect(projectPath);

      if (tools.isEmpty) {
        aiDetecting.complete(
          'No AI tool directories found (will generate defaults)',
        );
      } else {
        aiDetecting.complete(
          'Detected: ${tools.map((t) => t.displayName).join(', ')}',
        );
      }

      // ── Step 4: Create .valenty.yaml ────────────────────────────────
      final configProgress = _logger.progress('Creating .valenty.yaml');
      final valentyConfig = ValentyConfig();

      if (valentyConfig.exists()) {
        configProgress.complete('.valenty.yaml already exists (kept)');
      } else {
        final model = ValentyConfigModel(
          projectName: projectInfo.name,
          projectType: projectInfo.type.name,
          aiToolsGenerateFor: tools.map((t) => t.name).toList(),
        );
        await valentyConfig.save(model);
        configProgress.complete('Created .valenty.yaml');
      }

      // ── Step 5: Add valenty_dsl as dev_dependency ───────────────────
      final depProgress = _logger.progress('Adding valenty_dsl dependency');
      final added = await _addValentyDslDependency(pubspecFile);
      if (added) {
        depProgress.complete('Added valenty_dsl to dev_dependencies');
      } else {
        depProgress.complete('valenty_dsl already in dev_dependencies');
      }

      // ── Step 6: Generate AI skill files ─────────────────────────────
      final skillProgress = _logger.progress('Generating AI skill files');
      await _generateSkills(tools, projectPath);
      skillProgress.complete('AI skill files generated');

      // ── Step 7: Run pub get ─────────────────────────────────────────
      final pubGetProgress = _logger.progress('Running pub get');
      final isFlutter = projectInfo.hasFlutter;
      final pubGetResult = await Process.run(
        isFlutter ? 'flutter' : 'dart',
        ['pub', 'get'],
        workingDirectory: projectPath,
      );

      if (pubGetResult.exitCode == 0) {
        pubGetProgress.complete('Dependencies resolved');
      } else {
        pubGetProgress.fail(
          'pub get failed (exit code ${pubGetResult.exitCode})',
        );
        final stderr = (pubGetResult.stderr as String).trim();
        if (stderr.isNotEmpty) {
          _logger.err(stderr);
        }
      }
    } on FileSystemException {
      detecting.fail('Failed to detect project type');
      return;
    }

    _logger.info('');
    _logger.success('Valenty initialized successfully!');
    _logger.info('');
    _logger.info('Next steps:');
    _logger.info(
      '  Ask your AI: "Scaffold the <Feature> builders for acceptance testing"',
    );
    _logger.info(
      '  Ask your AI: "Write test for: Given a product with unit price \$20..."',
    );
    _logger.info('');
    _logger.info('Run "valenty doctor" to verify your setup.');
  }

  /// Add `valenty_dsl` to `dev_dependencies` in pubspec.yaml.
  ///
  /// Returns `true` if added, `false` if already present.
  Future<bool> _addValentyDslDependency(File pubspecFile) async {
    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    // Check if already present
    if (yaml['dev_dependencies'] is YamlMap) {
      final devDeps = yaml['dev_dependencies'] as YamlMap;
      if (devDeps.containsKey('valenty_dsl')) {
        return false;
      }
    }

    final editor = YamlEditor(content);

    // Ensure dev_dependencies section exists
    if (yaml['dev_dependencies'] == null) {
      editor.update(['dev_dependencies'], {'valenty_dsl': '^0.1.0'});
    } else {
      editor.update(['dev_dependencies', 'valenty_dsl'], '^0.1.0');
    }

    await pubspecFile.writeAsString(editor.toString());
    return true;
  }

  /// Generate AI skill files for detected (or default) tools.
  Future<void> _generateSkills(
    List<AiToolType> tools,
    String projectPath,
  ) async {
    // Always generate Claude skill (most common and comprehensive)
    await ClaudeSkillGenerator(logger: _logger).generate(projectPath);

    // Generate for each detected tool
    for (final tool in tools) {
      switch (tool) {
        case AiToolType.claude:
          // Already generated above
          break;
        case AiToolType.cursor:
          await CursorRuleGenerator(logger: _logger).generate(projectPath);
        case AiToolType.codex:
          // AGENTS.md covers this
          break;
        case AiToolType.openCode:
          await OpenCodeAgentGenerator(logger: _logger).generate(projectPath);
      }
    }

    // Always generate AGENTS.md (portable, works with Codex and OpenCode)
    await CodexAgentGenerator(logger: _logger).generate(projectPath);
  }
}
