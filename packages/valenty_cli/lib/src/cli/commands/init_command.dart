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
  InitCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'scope',
      help: 'Where to install AI skill files.\n'
          '  project — <git-root>/.claude/skills/ (this project only, default)\n'
          '  user    — ~/.claude/skills/ (available in ALL projects)',
      allowed: ['project', 'user'],
      defaultsTo: 'project',
      valueHelp: 'project|user',
    );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize Valenty: add valenty_test dependency, create config, '
      'install AI skills.';

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

      // ── Step 3: Determine skill install path ────────────────────────
      final scopeFlag = argResults?['scope'] as String? ?? 'project';
      final String skillInstallPath;

      if (scopeFlag == 'user') {
        final userHome = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '';
        skillInstallPath = userHome;
      } else {
        final gitRoot = _findGitRoot(projectPath);
        skillInstallPath = gitRoot ?? projectPath;
      }

      _logger.info(
        'AI skills scope: $scopeFlag ($skillInstallPath)',
      );

      // ── Step 4: Detect AI tools ─────────────────────────────────────
      final aiDetecting = _logger.progress('Detecting AI tools');
      final aiDetector = AiToolDetector();
      final tools = aiDetector.detect(skillInstallPath);

      if (tools.isEmpty) {
        aiDetecting.complete(
          'No AI tool directories found (will generate defaults)',
        );
      } else {
        aiDetecting.complete(
          'Detected: ${tools.map((t) => t.displayName).join(', ')}',
        );
      }

      // ── Step 5: Create .valenty.yaml ────────────────────────────────
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

      // ── Step 6: Add valenty_test as dev_dependency ───────────────────
      final depProgress = _logger.progress('Adding valenty_test dependency');
      final added = await _addValentyDslDependency(pubspecFile);
      if (added) {
        depProgress.complete('Added valenty_test to dev_dependencies');
      } else {
        depProgress.complete('valenty_test already in dev_dependencies');
      }

      // ── Step 7: Generate AI skill files ─────────────────────────────
      final skillProgress = _logger.progress('Generating AI skill files');
      await _generateSkills(
        tools,
        skillInstallPath,
        isFlutter: projectInfo.hasFlutter,
      );
      skillProgress.complete('AI skill files generated');

      // ── Step 8: Run pub get ─────────────────────────────────────────
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

      // ── Step 9: Success message ─────────────────────────────────────
      _logger.info('');
      _logger.success('Valenty initialized successfully!');
      _logger.info('');
      _logger.info('  valenty_test: dev_dependency');
      _logger.info('  config: .valenty.yaml');
      _logger.info('  skills: $skillInstallPath');
      _logger.info('');
      _logger.info(
        'Next: tell your AI "Generate my first valentyTest scenarios"',
      );
    } on FileSystemException {
      detecting.fail('Failed to detect project type');
      return;
    }
  }

  /// Add `valenty_test` to `dev_dependencies` in pubspec.yaml.
  Future<bool> _addValentyDslDependency(File pubspecFile) async {
    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    if (yaml['dev_dependencies'] is YamlMap) {
      final devDeps = yaml['dev_dependencies'] as YamlMap;
      if (devDeps.containsKey('valenty_test')) {
        return false;
      }
    }

    final editor = YamlEditor(content);

    if (yaml['dev_dependencies'] == null) {
      editor.update(['dev_dependencies'], {'valenty_test': '^0.2.2'});
    } else {
      editor.update(['dev_dependencies', 'valenty_test'], '^0.2.2');
    }

    await pubspecFile.writeAsString(editor.toString());
    return true;
  }

  /// Find the git root by walking up from [startPath].
  String? _findGitRoot(String startPath) {
    var current = startPath;
    while (true) {
      if (Directory(p.join(current, '.git')).existsSync()) {
        return current;
      }
      final parent = p.dirname(current);
      if (parent == current) return null;
      current = parent;
    }
  }

  /// Generate AI skill files for detected (or default) tools.
  Future<void> _generateSkills(
    List<AiToolType> tools,
    String projectPath, {
    bool isFlutter = false,
  }) async {
    await ClaudeSkillGenerator(logger: _logger).generate(
      projectPath,
      isFlutter: isFlutter,
    );

    for (final tool in tools) {
      switch (tool) {
        case AiToolType.claude:
          break;
        case AiToolType.cursor:
          await CursorRuleGenerator(logger: _logger).generate(
            projectPath,
            isFlutter: isFlutter,
          );
        case AiToolType.codex:
          break;
        case AiToolType.openCode:
          await OpenCodeAgentGenerator(logger: _logger).generate(
            projectPath,
            isFlutter: isFlutter,
          );
      }
    }

    await CodexAgentGenerator(logger: _logger).generate(
      projectPath,
      isFlutter: isFlutter,
    );
  }
}
