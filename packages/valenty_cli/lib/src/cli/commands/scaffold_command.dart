import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/scaffold/scaffold_generator.dart';

/// Parent command for `valenty scaffold`.
///
/// Subcommands:
/// - `valenty scaffold feature <name> --models <paths>`
class ScaffoldCommand extends Command<void> {
  ScaffoldCommand({required Logger logger}) : _logger = logger {
    addSubcommand(ScaffoldFeatureCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  String get name => 'scaffold';

  @override
  String get description =>
      'Generate builder scaffolds for acceptance testing.';
}

/// Subcommand: `valenty scaffold feature <feature_name> --models <paths>`
///
/// Generates the full builder tree (Scenario, GivenBuilder, DomainObjectBuilders,
/// WhenBuilder, ActionBuilder, ThenBuilder, AssertionBuilders) for a feature
/// based on the provided model files.
class ScaffoldFeatureCommand extends Command<void> {
  ScaffoldFeatureCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'models',
      abbr: 'm',
      help: 'Comma-separated paths to Dart model files '
          '(e.g., lib/models/order.dart,lib/models/product.dart).',
      mandatory: true,
    );
  }

  final Logger _logger;

  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate a full builder tree for a feature from model files.';

  @override
  String get invocation =>
      'valenty scaffold feature <feature_name> --models <paths>';

  @override
  Future<void> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.err(
        'Missing feature name.\n'
        'Usage: valenty scaffold feature <feature_name> --models <paths>',
      );
      return;
    }

    final featureName = rest.first;
    final modelsArg = args['models'] as String;

    if (modelsArg.trim().isEmpty) {
      _logger.err(
        'No model paths provided.\n'
        'Usage: valenty scaffold feature $featureName '
        '--models lib/models/order.dart,lib/models/product.dart',
      );
      return;
    }

    final modelPaths = modelsArg
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (modelPaths.isEmpty) {
      _logger.err('No valid model paths provided.');
      return;
    }

    // Validate that model files exist
    final projectPath = Directory.current.path;
    final missingFiles = <String>[];
    for (final modelPath in modelPaths) {
      final file = File(
        modelPath.startsWith('/') ? modelPath : '$projectPath/$modelPath',
      );
      if (!file.existsSync()) {
        missingFiles.add(modelPath);
      }
    }

    if (missingFiles.isNotEmpty) {
      _logger.err(
        'The following model files were not found:\n'
        '${missingFiles.map((f) => '  - $f').join('\n')}\n\n'
        'Make sure the paths are relative to the project root.',
      );
      return;
    }

    _logger.info('');
    _logger.info(
      'Scaffolding feature: ${lightCyan.wrap(featureName)}',
    );
    _logger.info(
      'Models: ${modelPaths.map((p) => lightCyan.wrap(p)).join(', ')}',
    );
    _logger.info('');

    final generator = ScaffoldGenerator(logger: _logger);
    await generator.generate(
      featureName: featureName,
      modelPaths: modelPaths,
      projectPath: projectPath,
    );
  }
}
