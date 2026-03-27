import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'scaffold_then_builder.dart';

/// Fluent assertion builder for scaffold generated files.
///
/// Available assertions:
/// - `.hasScenarioFile()` — assert scenario file exists
/// - `.hasGivenBuilder()` — assert given builder exists
/// - `.hasDomainObjectBuilder(String className)` — assert domain object builder exists
/// - `.hasWhenBuilder()` — assert when builder exists
/// - `.hasThenBuilder()` — assert then builder exists
/// - `.hasAssertionBuilder()` — assert assertion builder exists
/// - `.fileCount(int expected)` — assert total generated file count
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ScaffoldAssertionBuilder extends AssertionBuilder {
  ScaffoldAssertionBuilder(super.scenario);

  String _outputDir(TestContext ctx) {
    final projectPath = ctx.get<String>('projectPath');
    final featureName = ctx.get<String>('featureName');
    return p.join(projectPath, 'test', 'valenty', 'features', featureName);
  }

  /// Assert the scenario file exists.
  ScaffoldAssertionBuilder hasScenarioFile() {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final featureName = ctx.get<String>('featureName');
      final file = File(p.join(outputDir, '${featureName}_scenario.dart'));
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected scenario file at ${file.path}',
      );
    });
    return this;
  }

  /// Assert the given builder file exists.
  ScaffoldAssertionBuilder hasGivenBuilder() {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final featureName = ctx.get<String>('featureName');
      final file = File(
        p.join(outputDir, 'builders', 'given', '${featureName}_given_builder.dart'),
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected given builder at ${file.path}',
      );
    });
    return this;
  }

  /// Assert a domain object builder exists for a specific class name.
  ScaffoldAssertionBuilder hasDomainObjectBuilder(String className) {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final snakeCase = _toSnakeCase(className);
      final file = File(
        p.join(outputDir, 'builders', 'given', '${snakeCase}_given_builder.dart'),
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected domain object builder for $className at ${file.path}',
      );
    });
    return this;
  }

  /// Assert the when builder file exists.
  ScaffoldAssertionBuilder hasWhenBuilder() {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final featureName = ctx.get<String>('featureName');
      final file = File(
        p.join(outputDir, 'builders', 'when', '${featureName}_when_builder.dart'),
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected when builder at ${file.path}',
      );
    });
    return this;
  }

  /// Assert the then builder file exists.
  ScaffoldAssertionBuilder hasThenBuilder() {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final featureName = ctx.get<String>('featureName');
      final file = File(
        p.join(outputDir, 'builders', 'then', '${featureName}_then_builder.dart'),
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected then builder at ${file.path}',
      );
    });
    return this;
  }

  /// Assert an assertion builder file exists for a specific class name.
  ScaffoldAssertionBuilder hasAssertionBuilder(String className) {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final snakeCase = _toSnakeCase(className);
      final file = File(
        p.join(outputDir, 'builders', 'then', '${snakeCase}_assertion_builder.dart'),
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected assertion builder for $className at ${file.path}',
      );
    });
    return this;
  }

  /// Assert the total number of generated files.
  ScaffoldAssertionBuilder fileCount(int expected) {
    addAssertionStep((ctx) {
      final outputDir = _outputDir(ctx);
      final dir = Directory(outputDir);
      if (!dir.existsSync()) {
        fail('Output directory does not exist: $outputDir');
      }
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(
        files.length,
        equals(expected),
        reason:
            'Expected $expected generated files, found ${files.length}: '
            '${files.map((f) => p.relative(f.path, from: outputDir)).toList()}',
      );
    });
    return this;
  }

  /// Add more assertions.
  ScaffoldAndThenBuilder get and => ScaffoldAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);

  /// Convert a class name to snake_case.
  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}
