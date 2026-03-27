import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../detection/project_detector.dart';

/// Wraps `dart test` / `flutter test` with Valenty-specific targeting.
///
/// Examples:
/// ```bash
/// valenty test                              # All valenty scenarios
/// valenty test --feature order              # One feature
/// valenty test --scenario "base price"      # Name pattern
/// valenty test --reporter expanded          # Pass to dart/flutter test
/// valenty test --coverage                   # Coverage
/// ```
class TestCommand extends Command<void> {
  TestCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Run tests for a specific feature (subdirectory name under '
            'test/valenty/features/).',
      )
      ..addOption(
        'scenario',
        abbr: 's',
        help: 'Filter scenarios by name pattern (passed as --name to the test '
            'runner).',
      )
      ..addOption(
        'reporter',
        abbr: 'r',
        help: 'Test reporter to use (e.g. expanded, compact, json).',
      )
      ..addFlag(
        'coverage',
        help: 'Collect coverage information.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get name => 'test';

  @override
  String get description =>
      'Run Valenty acceptance tests (wraps dart test / flutter test).';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    // ── Step 1: Validate project ──────────────────────────────────────────
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      _logger.err(
        'No pubspec.yaml found in the current directory.\n'
        'Run this command from the root of a Dart or Flutter project.',
      );
      throw ExitCodeException(ExitCode.noInput.code);
    }

    // ── Step 2: Detect project type (Flutter vs Dart) ─────────────────────
    final detecting = _logger.progress('Detecting project type');
    final ProjectDetector detector;
    bool isFlutter;
    try {
      detector = ProjectDetector();
      final projectInfo = await detector.detect(projectPath);
      isFlutter = projectInfo.hasFlutter;
      detecting.complete(
        'Detected: ${projectInfo.type.name} (${projectInfo.name})',
      );
    } on FileSystemException {
      detecting.fail('Failed to detect project type');
      throw ExitCodeException(ExitCode.unavailable.code);
    }

    // ── Step 3: Resolve test target path ──────────────────────────────────
    final valentyTestDir = p.join(projectPath, 'test', 'valenty', 'features');
    final feature = argResults?['feature'] as String?;

    String testTarget;
    if (feature != null) {
      final featureDir = p.join(valentyTestDir, feature);
      if (!Directory(featureDir).existsSync()) {
        _logger.err(
          'Feature directory not found: $featureDir\n'
          'Available features:',
        );
        _listAvailableFeatures(valentyTestDir);
        throw ExitCodeException(ExitCode.usage.code);
      }
      testTarget = featureDir;
    } else {
      if (!Directory(valentyTestDir).existsSync()) {
        _logger.err(
          'Valenty test directory not found: $valentyTestDir\n'
          'Run "valenty init" first, then create your feature scenarios.',
        );
        throw ExitCodeException(ExitCode.usage.code);
      }
      testTarget = valentyTestDir;
    }

    // ── Step 4: Build command arguments ───────────────────────────────────
    final executable = isFlutter ? 'flutter' : 'dart';
    final args = <String>['test'];

    // Scenario name filter
    final scenario = argResults?['scenario'] as String?;
    if (scenario != null) {
      args.addAll(['--name', scenario]);
    }

    // Reporter
    final reporter = argResults?['reporter'] as String?;
    if (reporter != null) {
      args.addAll(['--reporter', reporter]);
    }

    // Coverage
    final coverage = argResults?['coverage'] as bool? ?? false;
    if (coverage) {
      args.add('--coverage');
    }

    // Test target directory (relative to project root)
    args.add(p.relative(testTarget, from: projectPath));

    // ── Step 5: Run tests with streaming output ───────────────────────────
    _logger.info('');
    _logger.info(
      lightCyan.wrap('Running: $executable ${args.join(' ')}'),
    );
    _logger.info('');

    final process = await Process.start(
      executable,
      args,
      workingDirectory: projectPath,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    _logger.info('');
    if (exitCode == 0) {
      _logger.success('All Valenty tests passed!');
    } else {
      _logger.err('Tests failed with exit code $exitCode.');
    }

    if (exitCode != 0) {
      throw ExitCodeException(exitCode);
    }
  }

  /// Lists available feature directories to help the user pick the right name.
  void _listAvailableFeatures(String valentyTestDir) {
    final dir = Directory(valentyTestDir);
    if (!dir.existsSync()) {
      _logger.info('  (no features directory found)');
      return;
    }

    final features = dir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    if (features.isEmpty) {
      _logger.info('  (no features found)');
    } else {
      for (final feature in features) {
        _logger.info('  - $feature');
      }
    }
  }
}

/// Exception that carries a process exit code.
class ExitCodeException implements Exception {
  const ExitCodeException(this.code);
  final int code;

  @override
  String toString() => 'ExitCodeException(code: $code)';
}
