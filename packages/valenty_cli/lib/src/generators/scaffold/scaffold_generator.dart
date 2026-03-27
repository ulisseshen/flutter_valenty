import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../analyzers/model_analyzer.dart';
import 'templates/assertion_builder_template.dart' as assertion_tpl;
import 'templates/domain_object_template.dart' as domain_tpl;
import 'templates/given_builder_template.dart' as given_tpl;
import 'templates/scenario_template.dart' as scenario_tpl;
import 'templates/then_builder_template.dart' as then_tpl;
import 'templates/when_builder_template.dart' as when_tpl;

/// Orchestrates the generation of the full builder tree for a feature.
class ScaffoldGenerator {
  ScaffoldGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generate the complete scaffold for a feature.
  ///
  /// [featureName] is the feature name in snake_case (e.g., "order").
  /// [modelPaths] is a list of paths to Dart model files.
  /// [projectPath] is the root project directory.
  Future<void> generate({
    required String featureName,
    required List<String> modelPaths,
    required String projectPath,
  }) async {
    final featureSnake = _toSnakeCase(featureName);
    final featurePascal = _toPascalCase(featureName);

    // Parse all model files
    final analyzer = ModelAnalyzer();
    final models = <ModelInfo>[];
    final modelAbsolutePaths = <ModelInfo, String>{};

    for (final modelPath in modelPaths) {
      final absolutePath = p.isAbsolute(modelPath)
          ? modelPath
          : p.join(projectPath, modelPath);

      final progress = _logger.progress('Parsing $modelPath');
      try {
        final parsed = analyzer.parseFile(absolutePath);
        if (parsed.isEmpty) {
          progress.fail('No classes found in $modelPath');
          continue;
        }
        for (final model in parsed) {
          models.add(model);
          modelAbsolutePaths[model] = absolutePath;
          progress.complete(
            'Found ${model.className} with ${model.fields.length} fields',
          );
        }
      } on FileSystemException {
        progress.fail('File not found: $modelPath');
      }
    }

    if (models.isEmpty) {
      _logger.err('No models found. Cannot generate scaffold.');
      return;
    }

    _logger.info('');
    _logger.info('Generating $featurePascal feature scaffold...');

    // Determine the output directory
    final outputDir = p.join(
      projectPath,
      'test',
      'valenty',
      'features',
      featureSnake,
    );

    // Create directory structure
    final givenDir = p.join(outputDir, 'builders', 'given');
    final whenDir = p.join(outputDir, 'builders', 'when');
    final thenDir = p.join(outputDir, 'builders', 'then');

    await Directory(givenDir).create(recursive: true);
    await Directory(whenDir).create(recursive: true);
    await Directory(thenDir).create(recursive: true);

    // Calculate relative import paths for models
    String modelImportPath(ModelInfo model) {
      final absModelPath = modelAbsolutePaths[model]!;
      // Calculate relative path from the builder file to the model file
      // The builder files are in test/valenty/features/<feature>/builders/<phase>/
      // Models are typically in lib/models/
      final fromGiven = p.relative(absModelPath, from: givenDir);
      return fromGiven;
    }

    String modelImportPathFromThen(ModelInfo model) {
      final absModelPath = modelAbsolutePaths[model]!;
      return p.relative(absModelPath, from: thenDir);
    }

    // 1. Generate scenario file
    final scenarioProgress = _logger.progress('Generating scenario');
    await _writeFile(
      p.join(outputDir, '${featureSnake}_scenario.dart'),
      scenario_tpl.generateScenario(
        featureName: featureName,
        featureSnake: featureSnake,
        featurePascal: featurePascal,
        models: models,
      ),
    );
    scenarioProgress.complete('${featurePascal}Scenario');

    // 2. Generate GivenBuilder
    final givenProgress = _logger.progress('Generating given builder');
    await _writeFile(
      p.join(givenDir, '${featureSnake}_given_builder.dart'),
      given_tpl.generateGivenBuilder(
        featurePascal: featurePascal,
        featureSnake: featureSnake,
        models: models,
      ),
    );
    givenProgress.complete('${featurePascal}GivenBuilder');

    // 3. Generate DomainObjectBuilders (one per model, in given/)
    for (final model in models) {
      final domainProgress = _logger.progress(
        'Generating ${model.className} given builder',
      );
      await _writeFile(
        p.join(givenDir, '${model.snakeCase}_given_builder.dart'),
        domain_tpl.generateDomainObjectBuilder(
          featurePascal: featurePascal,
          featureSnake: featureSnake,
          model: model,
          modelImportPath: modelImportPath(model),
        ),
      );
      domainProgress.complete('${model.className}GivenBuilder');
    }

    // 4. Generate WhenBuilder
    final whenProgress = _logger.progress('Generating when builder');
    await _writeFile(
      p.join(whenDir, '${featureSnake}_when_builder.dart'),
      when_tpl.generateWhenBuilder(
        featurePascal: featurePascal,
        featureSnake: featureSnake,
        models: models,
      ),
    );
    whenProgress.complete('${featurePascal}WhenBuilder');

    // 5. Generate action builder (in when/)
    final actionProgress = _logger.progress('Generating action builder');
    await _writeFile(
      p.join(whenDir, '${featureSnake}_action_builder.dart'),
      when_tpl.generateActionBuilder(
        featurePascal: featurePascal,
        featureSnake: featureSnake,
        models: models,
      ),
    );
    actionProgress.complete('Execute${featurePascal}WhenBuilder');

    // 6. Generate ThenBuilder
    final thenProgress = _logger.progress('Generating then builder');
    await _writeFile(
      p.join(thenDir, '${featureSnake}_then_builder.dart'),
      then_tpl.generateThenBuilder(
        featurePascal: featurePascal,
        featureSnake: featureSnake,
        models: models,
      ),
    );
    thenProgress.complete('${featurePascal}ThenBuilder');

    // 7. Generate AssertionBuilders (one per model, in then/)
    for (final model in models) {
      final assertionProgress = _logger.progress(
        'Generating ${model.className} assertion builder',
      );
      await _writeFile(
        p.join(thenDir, '${model.snakeCase}_assertion_builder.dart'),
        assertion_tpl.generateAssertionBuilder(
          featurePascal: featurePascal,
          featureSnake: featureSnake,
          model: model,
          modelImportPath: modelImportPathFromThen(model),
        ),
      );
      assertionProgress.complete('${model.className}AssertionBuilder');
    }

    _logger.info('');
    _logger.success('Scaffold generated successfully!');
    _logger.info('');
    _logger.info('Generated files:');
    _logger.info('  $outputDir/');
    _logger.info('    ${featureSnake}_scenario.dart');
    _logger.info('    builders/');
    _logger.info('      given/');
    _logger.info('        ${featureSnake}_given_builder.dart');
    for (final model in models) {
      _logger.info('        ${model.snakeCase}_given_builder.dart');
    }
    _logger.info('      when/');
    _logger.info('        ${featureSnake}_when_builder.dart');
    _logger.info('        ${featureSnake}_action_builder.dart');
    _logger.info('      then/');
    _logger.info('        ${featureSnake}_then_builder.dart');
    for (final model in models) {
      _logger.info('        ${model.snakeCase}_assertion_builder.dart');
    }
    _logger.info('');
    _logger.info('Next steps:');
    _logger.info(
      '  1. Implement applyToContext() in the action builder '
      '(builders/when/${featureSnake}_action_builder.dart)',
    );
    _logger.info(
      '  2. Implement shouldSucceed()/shouldFail() assertions '
      '(builders/then/${featureSnake}_then_builder.dart)',
    );
    _logger.info('  3. Write your first test using ${featurePascal}Scenario!');
  }

  /// Write content to a file, creating parent directories as needed.
  Future<void> _writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Convert a string to snake_case.
  String _toSnakeCase(String input) {
    // Handle already snake_case input
    if (input.contains('_') && input == input.toLowerCase()) {
      return input;
    }
    // Convert PascalCase or camelCase to snake_case
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Convert a string to PascalCase.
  String _toPascalCase(String input) {
    // Handle snake_case input
    if (input.contains('_')) {
      return input
          .split('_')
          .map((part) {
            if (part.isEmpty) return '';
            return part[0].toUpperCase() + part.substring(1).toLowerCase();
          })
          .join();
    }
    // Handle camelCase input — just capitalize first letter
    if (input.isNotEmpty) {
      return input[0].toUpperCase() + input.substring(1);
    }
    return input;
  }
}
