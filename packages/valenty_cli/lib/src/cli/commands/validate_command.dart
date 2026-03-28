import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../config/valenty_config.dart';
import '../../validators/builder_validator.dart';
import '../../validators/validation_result.dart';

/// CLI command that validates Valenty builder files for correctness.
///
/// Usage:
///   valenty validate              # validate all features
///   valenty validate --feature order  # validate a single feature
class ValidateCommand extends Command<void> {
  ValidateCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Validate only the specified feature.',
    );
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to the project root (defaults to current directory).',
    );
  }

  final Logger _logger;

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validate builder files for correctness and conventions.';

  @override
  Future<void> run() async {
    final featureFilter = argResults?['feature'] as String?;
    final projectPath =
        argResults?['path'] as String? ?? Directory.current.path;

    _logger.info('Valenty Validate');
    _logger.info('=' * 40);
    _logger.info('');

    // Resolve features path from config or default
    final featuresPath = await _resolveFeaturesPath(projectPath);
    if (featuresPath == null) {
      _logger.info(
        '${red.wrap('✗')} Could not determine features directory.',
      );
      _logger.info(
        '  Run "valenty init" or check dsl_output_directory '
        'in .valenty.yaml',
      );
      _logger.info('');
      exitCode = 1;
      return;
    }

    _logger.info('Scanning: $featuresPath');
    _logger.info('');

    final validator = BuilderValidator();
    final ValidationResult result;

    if (featureFilter != null) {
      // Validate a single feature
      final featurePath = p.join(featuresPath, featureFilter);
      final featureResult =
          validator.validateFeature(featurePath, featureFilter);
      result = ValidationResult(features: [featureResult]);
    } else {
      // Validate all features
      result = validator.validateAll(featuresPath);
    }

    _printResults(result);
    _printSummary(result);

    exitCode = result.isValid ? 0 : 1;
  }

  /// Resolve the path to the features directory.
  ///
  /// Reads from .valenty.yaml config if available, otherwise uses
  /// the default `test/valenty/features`.
  Future<String?> _resolveFeaturesPath(String projectPath) async {
    final config = ValentyConfig();
    String outputDir = 'test/';

    if (config.exists(projectPath)) {
      try {
        final configModel = await config.load(projectPath);
        outputDir = configModel.dslOutputDirectory;
      } on Exception {
        // Fall back to default
      }
    }

    // Normalize the output directory and append valenty/features
    final basePath = p.join(projectPath, outputDir, 'valenty', 'features');
    final normalized = p.normalize(basePath);

    if (Directory(normalized).existsSync()) {
      return normalized;
    }

    // Try without the valenty/features suffix (in case the config
    // already points there)
    final directPath = p.join(projectPath, outputDir);
    if (Directory(directPath).existsSync()) {
      // Check if there are feature-like subdirectories
      final dirs =
          Directory(directPath).listSync().whereType<Directory>().where((d) {
        final name = p.basename(d.path);
        return !name.startsWith('.');
      });
      if (dirs.isNotEmpty) {
        return directPath;
      }
    }

    return normalized;
  }

  /// Print validation results for each feature.
  void _printResults(ValidationResult result) {
    for (final feature in result.features) {
      _logger.info(
        '${_featureIcon(feature)} Feature: ${styleBold.wrap(feature.featureName)}',
      );

      if (feature.issues.isEmpty) {
        _logger.info(
          '  ${lightGreen.wrap('✓')} All checks passed',
        );
        _logger.info('');
        continue;
      }

      for (final issue in feature.issues) {
        final icon = _issueIcon(issue);
        final location =
            issue.file != null ? ' ${darkGray.wrap('(${issue.file})')}' : '';
        _logger.info('  $icon ${issue.message}$location');

        if (issue.suggestion != null) {
          _logger.info(
            '    ${darkGray.wrap('hint: ${issue.suggestion}')}',
          );
        }
      }

      _logger.info('');
    }
  }

  /// Print the final summary line.
  void _printSummary(ValidationResult result) {
    _logger.info('─' * 40);

    final featureCount = result.features.length;
    final featureLabel = featureCount == 1 ? 'feature' : 'features';

    if (result.isValid && !result.hasWarnings) {
      _logger.info(
        '${lightGreen.wrap('✓')} $featureCount $featureLabel validated '
        'successfully.',
      );
    } else if (result.isValid) {
      _logger.info(
        '${yellow.wrap('○')} $featureCount $featureLabel validated with '
        '${result.totalWarnings} '
        '${result.totalWarnings == 1 ? 'warning' : 'warnings'}.',
      );
    } else {
      _logger.info(
        '${red.wrap('✗')} Validation failed: '
        '${result.totalErrors} '
        '${result.totalErrors == 1 ? 'error' : 'errors'}'
        '${result.totalWarnings > 0 ? ', ${result.totalWarnings} ${result.totalWarnings == 1 ? 'warning' : 'warnings'}' : ''}.',
      );
    }

    _logger.info('');
  }

  /// Icon for a feature header based on its validation state.
  String _featureIcon(FeatureValidationResult feature) {
    if (feature.hasErrors) return red.wrap('✗')!;
    if (feature.hasWarnings) return yellow.wrap('○')!;
    return lightGreen.wrap('✓')!;
  }

  /// Icon for an individual issue.
  String _issueIcon(ValidationIssue issue) {
    switch (issue.severity) {
      case ValidationSeverity.error:
        return red.wrap('✗')!;
      case ValidationSeverity.warning:
        return yellow.wrap('○')!;
      case ValidationSeverity.info:
        return cyan.wrap('i')!;
    }
  }
}
