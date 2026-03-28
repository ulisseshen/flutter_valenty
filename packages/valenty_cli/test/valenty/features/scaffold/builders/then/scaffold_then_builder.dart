import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'scaffold_assertion_builder.dart';

/// ThenBuilder for the Scaffold feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert scaffold generation succeeded
/// - `.shouldFail()` — assert scaffold generation failed
/// - `.generatedFiles()` — fluent assertion builder for generated files
class ScaffoldThenBuilder extends ThenBuilder {
  ScaffoldThenBuilder(super.scenario);

  /// Assert the scaffold generation succeeded (produced files).
  ScaffoldThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final projectPath = ctx.get<String>('projectPath');
      final featureName = ctx.get<String>('featureName');
      final outputDir = p.join(
        projectPath,
        'test',
        'valenty',
        'features',
        featureName,
      );
      expect(
        Directory(outputDir).existsSync(),
        isTrue,
        reason: 'Expected scaffold output directory to exist at $outputDir',
      );
    });
    return ScaffoldThenTerminal(next);
  }

  /// Assert the scaffold generation failed (no files generated).
  ScaffoldThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final projectPath = ctx.get<String>('projectPath');
      final featureName = ctx.get<String>('featureName');
      final outputDir = p.join(
        projectPath,
        'test',
        'valenty',
        'features',
        featureName,
      );
      // Scaffold should fail: either the output dir doesn't exist,
      // or the scenario file was not generated (no models found case).
      final scenarioFile = File(
        p.join(outputDir, '${featureName}_scenario.dart'),
      );
      expect(
        scenarioFile.existsSync(),
        isFalse,
        reason: 'Expected scaffold to fail — no scenario file should exist',
      );
    });
    return ScaffoldThenTerminal(next);
  }

  /// Start a fluent assertion chain for generated files.
  ScaffoldAssertionBuilder generatedFiles() =>
      ScaffoldAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ScaffoldThenTerminal {
  ScaffoldThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  ScaffoldAndThenBuilder get and => ScaffoldAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Scaffold feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class ScaffoldAndThenBuilder extends AndThenBuilder {
  ScaffoldAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for the generated files.
  ScaffoldAssertionBuilder generatedFiles() =>
      ScaffoldAssertionBuilder(scenario);
}
