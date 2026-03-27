import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../analyzers/builder_introspector.dart';
import '../../analyzers/models/builder_info.dart';
import '../../analyzers/models/feature_info.dart';

/// `valenty list` — introspect the project's Valenty builders.
///
/// Subcommands:
/// - `list features` — list all discovered features
/// - `list builders` — list builders (optionally filtered by feature)
class ListCommand extends Command<void> {
  ListCommand({required Logger logger}) : _logger = logger {
    addSubcommand(_ListFeaturesCommand(logger: logger));
    addSubcommand(_ListBuildersCommand(logger: logger));
  }

  final Logger _logger;

  @override
  String get name => 'list';

  @override
  String get description =>
      'List Valenty features and builders in the current project.';

  @override
  Future<void> run() async {
    // When run without a subcommand, print usage.
    _logger.info(usage);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// list features
// ─────────────────────────────────────────────────────────────────────────────

class _ListFeaturesCommand extends Command<void> {
  _ListFeaturesCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'features';

  @override
  String get description => 'List all Valenty features in the project.';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;
    final introspector = BuilderIntrospector();
    final features = introspector.inspect(projectPath);

    if (features.isEmpty) {
      _logger.info(
        '${yellow.wrap('○')} No Valenty features found.\n'
        '  Expected location: test/valenty/features/<feature_name>/',
      );
      return;
    }

    _logger.info('Valenty Features');
    _logger.info('${'=' * 40}\n');

    for (final feature in features) {
      _printFeatureTree(feature);
      _logger.info('');
    }

    _logger.info(
      '${lightGreen.wrap('✓')} '
      '${features.length} feature(s) found.',
    );
  }

  void _printFeatureTree(FeatureInfo feature) {
    _logger.info(
      '${lightCyan.wrap('■')} ${styleBold.wrap(feature.name)}',
    );

    if (feature.scenarioClass.isNotEmpty) {
      _logger.info('  Scenario: ${feature.scenarioClass}');
    }

    final givenBuilders = feature.buildersForPhase('given');
    final whenBuilders = feature.buildersForPhase('when');
    final thenBuilders = feature.buildersForPhase('then');

    if (givenBuilders.isNotEmpty) {
      _logger.info('  ${lightGreen.wrap('Given')}');
      for (final b in givenBuilders) {
        _printBuilderBranch(b, isLast: b == givenBuilders.last);
      }
    }

    if (whenBuilders.isNotEmpty) {
      _logger.info('  ${lightYellow.wrap('When')}');
      for (final b in whenBuilders) {
        _printBuilderBranch(b, isLast: b == whenBuilders.last);
      }
    }

    if (thenBuilders.isNotEmpty) {
      _logger.info('  ${lightRed.wrap('Then')}');
      for (final b in thenBuilders) {
        _printBuilderBranch(b, isLast: b == thenBuilders.last);
      }
    }
  }

  void _printBuilderBranch(BuilderInfo builder, {required bool isLast}) {
    final connector = isLast ? '└──' : '├──';
    final childPrefix = isLast ? '    ' : '│   ';

    _logger.info(
      '    $connector ${builder.className} (${builder.kindLabel})',
    );

    for (var i = 0; i < builder.methods.length; i++) {
      final method = builder.methods[i];
      final isMethodLast = i == builder.methods.length - 1;
      final methodConnector = isMethodLast ? '└──' : '├──';
      final params = method.parameters.isEmpty
          ? '()'
          : '(${method.parameters.join(', ')})';

      _logger.info(
        '    $childPrefix $methodConnector ${method.name}$params'
        ' -> ${method.returnType}',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// list builders
// ─────────────────────────────────────────────────────────────────────────────

class _ListBuildersCommand extends Command<void> {
  _ListBuildersCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Filter builders by feature name.',
    );
    argParser.addOption(
      'phase',
      abbr: 'p',
      help: 'Filter builders by phase (given, when, then).',
      allowed: ['given', 'when', 'then'],
    );
  }

  final Logger _logger;

  @override
  String get name => 'builders';

  @override
  String get description =>
      'List all Valenty builders (optionally filtered by --feature or --phase).';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;
    final introspector = BuilderIntrospector();
    var features = introspector.inspect(projectPath);

    final featureFilter = argResults?['feature'] as String?;
    final phaseFilter = argResults?['phase'] as String?;

    if (featureFilter != null) {
      features = features
          .where(
            (f) => f.name.toLowerCase() == featureFilter.toLowerCase(),
          )
          .toList();

      if (features.isEmpty) {
        _logger.err('Feature "$featureFilter" not found.');
        return;
      }
    }

    if (features.isEmpty) {
      _logger.info(
        '${yellow.wrap('○')} No Valenty features found.\n'
        '  Expected location: test/valenty/features/<feature_name>/',
      );
      return;
    }

    _logger.info('Valenty Builders');
    _logger.info('${'=' * 40}\n');

    var totalBuilders = 0;

    for (final feature in features) {
      var builders = feature.builders;

      if (phaseFilter != null) {
        builders = feature.buildersForPhase(phaseFilter);
      }

      if (builders.isEmpty) continue;

      _logger.info(
        '${lightCyan.wrap('■')} ${styleBold.wrap(feature.name)}',
      );

      for (final builder in builders) {
        totalBuilders++;
        _logger.info(
          '  ${lightGreen.wrap('✓')} ${builder.className} '
          '(${builder.kindLabel}, ${builder.phase} phase)',
        );

        for (final method in builder.methods) {
          final params = method.parameters.isEmpty
              ? '()'
              : '(${method.parameters.join(', ')})';
          _logger.info(
            '      ${method.name}$params -> ${method.returnType}',
          );
        }
      }

      _logger.info('');
    }

    _logger.info(
      '${lightGreen.wrap('✓')} $totalBuilders builder(s) found.',
    );
  }
}
