import 'dart:io';

import 'package:path/path.dart' as p;

import 'validation_result.dart';

/// Validates Valenty builder files for a feature using regex-based parsing.
///
/// Checks:
/// 1. Directory structure (scenario file, given/when/then directories)
/// 2. Given builders extend GivenBuilder, have domain methods, domain objects
///    have applyToContext()
/// 3. When builders extend WhenBuilder, have action methods
/// 4. Then builders extend ThenBuilder, have assertions
/// 5. Naming conventions
class BuilderValidator {
  /// Validate all features found under the given base path.
  ///
  /// [basePath] should point to the valenty features directory,
  /// e.g., `test/valenty/features`.
  ValidationResult validateAll(String basePath) {
    final result = ValidationResult();
    final featuresDir = Directory(basePath);

    if (!featuresDir.existsSync()) {
      final singleResult = FeatureValidationResult(featureName: '<root>');
      singleResult.addError(
        'Features directory not found: $basePath',
        suggestion: 'Run "valenty init" or check dsl_output_directory '
            'in .valenty.yaml',
      );
      result.addFeature(singleResult);
      return result;
    }

    final featureDirs = featuresDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    if (featureDirs.isEmpty) {
      final singleResult = FeatureValidationResult(featureName: '<root>');
      singleResult.addInfo(
        'No feature directories found in $basePath',
      );
      result.addFeature(singleResult);
      return result;
    }

    for (final featureDir in featureDirs) {
      final featureName = p.basename(featureDir.path);
      result.addFeature(validateFeature(featureDir.path, featureName));
    }

    return result;
  }

  /// Validate a single feature by name.
  ///
  /// [featurePath] is the full path to the feature directory.
  /// [featureName] is the feature name (directory name).
  FeatureValidationResult validateFeature(
    String featurePath,
    String featureName,
  ) {
    final result = FeatureValidationResult(featureName: featureName);
    final featureDir = Directory(featurePath);

    if (!featureDir.existsSync()) {
      result.addError(
        'Feature directory not found: $featurePath',
        suggestion: 'Check that the feature "$featureName" exists.',
      );
      return result;
    }

    _validateStructure(featurePath, featureName, result);
    _validateScenarioFile(featurePath, featureName, result);
    _validateGivenBuilders(featurePath, featureName, result);
    _validateWhenBuilders(featurePath, featureName, result);
    _validateThenBuilders(featurePath, featureName, result);

    return result;
  }

  // ---------------------------------------------------------------------------
  // Structure validation
  // ---------------------------------------------------------------------------

  void _validateStructure(
    String featurePath,
    String featureName,
    FeatureValidationResult result,
  ) {
    // Check for scenario file
    final scenarioFile = _findScenarioFile(featurePath, featureName);
    if (scenarioFile == null) {
      result.addError(
        'Missing scenario file',
        file: featurePath,
        suggestion:
            'Create ${featureName}_scenario.dart extending FeatureScenario.',
      );
    }

    // Check for builders directory
    final buildersDir = Directory(p.join(featurePath, 'builders'));
    if (!buildersDir.existsSync()) {
      result.addError(
        'Missing builders/ directory',
        file: featurePath,
        suggestion: 'Create builders/given/, builders/when/, '
            'and builders/then/ directories.',
      );
      return;
    }

    // Check for given/when/then subdirectories
    final givenDir = Directory(p.join(featurePath, 'builders', 'given'));
    final whenDir = Directory(p.join(featurePath, 'builders', 'when'));
    final thenDir = Directory(p.join(featurePath, 'builders', 'then'));

    if (!givenDir.existsSync()) {
      result.addError(
        'Missing builders/given/ directory',
        file: p.join(featurePath, 'builders'),
        suggestion: 'Create the given/ directory with a GivenBuilder.',
      );
    }
    if (!whenDir.existsSync()) {
      result.addError(
        'Missing builders/when/ directory',
        file: p.join(featurePath, 'builders'),
        suggestion: 'Create the when/ directory with a WhenBuilder.',
      );
    }
    if (!thenDir.existsSync()) {
      result.addError(
        'Missing builders/then/ directory',
        file: p.join(featurePath, 'builders'),
        suggestion: 'Create the then/ directory with a ThenBuilder.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Scenario file validation
  // ---------------------------------------------------------------------------

  void _validateScenarioFile(
    String featurePath,
    String featureName,
    FeatureValidationResult result,
  ) {
    final scenarioFile = _findScenarioFile(featurePath, featureName);
    if (scenarioFile == null) return;

    final content = scenarioFile.readAsStringSync();
    final relativePath = p.relative(scenarioFile.path, from: featurePath);

    // Check naming convention: should be <feature>_scenario.dart
    final expectedName = '${featureName}_scenario.dart';
    final actualName = p.basename(scenarioFile.path);
    if (actualName != expectedName) {
      result.addWarning(
        'Scenario file name "$actualName" does not follow convention',
        file: relativePath,
        suggestion: 'Rename to "$expectedName".',
      );
    }

    // Check extends FeatureScenario
    final extendsPattern =
        RegExp(r'class\s+\w+\s+extends\s+FeatureScenario\s*<');
    if (!extendsPattern.hasMatch(content)) {
      result.addError(
        'Scenario class does not extend FeatureScenario<T>',
        file: relativePath,
        suggestion:
            'The scenario class should extend FeatureScenario<YourGivenBuilder>.',
      );
    }

    // Check createGivenBuilder override
    final createGivenPattern = RegExp(r'createGivenBuilder\s*\(');
    if (!createGivenPattern.hasMatch(content)) {
      result.addError(
        'Missing createGivenBuilder() override',
        file: relativePath,
        suggestion:
            'Override createGivenBuilder() to return your feature GivenBuilder.',
      );
    }

    // Check class naming convention: PascalCase of feature + Scenario
    final expectedClassName = '${_toPascalCase(featureName)}Scenario';
    final classNamePattern =
        RegExp(r'class\s+(' + expectedClassName + r')\s+extends');
    if (!classNamePattern.hasMatch(content)) {
      // Try to find any class name
      final anyClassPattern =
          RegExp(r'class\s+(\w+Scenario)\s+extends\s+FeatureScenario');
      final match = anyClassPattern.firstMatch(content);
      if (match != null) {
        final actualClassName = match.group(1)!;
        if (actualClassName != expectedClassName) {
          result.addWarning(
            'Scenario class "$actualClassName" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected class name: "$expectedClassName".',
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Given builders validation
  // ---------------------------------------------------------------------------

  void _validateGivenBuilders(
    String featurePath,
    String featureName,
    FeatureValidationResult result,
  ) {
    final givenDir = Directory(p.join(featurePath, 'builders', 'given'));
    if (!givenDir.existsSync()) return;

    final dartFiles = _listDartFiles(givenDir);
    if (dartFiles.isEmpty) {
      result.addError(
        'No Dart files in builders/given/',
        file: p.join('builders', 'given'),
        suggestion: 'Create a GivenBuilder for the $featureName feature.',
      );
      return;
    }

    // Find the main given builder (extends GivenBuilder)
    var hasMainGivenBuilder = false;

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final fileName = p.basename(file.path);
      final relativePath = p.join('builders', 'given', fileName);

      // Check if this is the main GivenBuilder
      final extendsGivenBuilder =
          RegExp(r'class\s+(\w+)\s+extends\s+GivenBuilder\b');
      final givenMatch = extendsGivenBuilder.firstMatch(content);

      if (givenMatch != null) {
        hasMainGivenBuilder = true;
        final className = givenMatch.group(1)!;

        // Naming convention: <Feature>GivenBuilder
        final expectedName = '${_toPascalCase(featureName)}GivenBuilder';
        if (className != expectedName) {
          result.addWarning(
            'Given builder class "$className" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected class name: "$expectedName".',
          );
        }

        // File naming convention
        final expectedFileName = '${featureName}_given_builder.dart';
        if (fileName != expectedFileName) {
          result.addWarning(
            'Given builder file "$fileName" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected file name: "$expectedFileName".',
          );
        }

        // Check for domain methods (methods returning a builder)
        final domainMethodPattern = RegExp(r'\w+\s+\w+\(\s*\)\s*(=>|{)');
        if (!domainMethodPattern.hasMatch(content)) {
          result.addWarning(
            'GivenBuilder has no domain object methods',
            file: relativePath,
            suggestion: 'Add methods like product(), user(), etc. '
                'that return DomainObjectBuilder subclasses.',
          );
        }

        // Check constructor takes super.scenario
        if (!content.contains('super.scenario')) {
          result.addWarning(
            'GivenBuilder constructor should use super.scenario',
            file: relativePath,
            suggestion: '$className(super.scenario);',
          );
        }
      }

      // Check if this is a DomainObjectBuilder in given phase
      final extendsDomainBuilder = RegExp(
          r'class\s+(\w+)\s+extends\s+DomainObjectBuilder\s*<\s*NeedsWhen\s*>',);
      final domainMatch = extendsDomainBuilder.firstMatch(content);

      if (domainMatch != null) {
        final className = domainMatch.group(1)!;

        // Check for applyToContext override
        final applyPattern = RegExp(r'void\s+applyToContext\s*\(');
        if (!applyPattern.hasMatch(content)) {
          result.addError(
            '$className is missing applyToContext() override',
            file: relativePath,
            suggestion:
                'Override applyToContext(TestContext ctx) to store domain '
                'objects in the test context.',
          );
        }

        // Check for withX() methods (fluent configuration)
        final withMethodPattern = RegExp(r'\w+\s+with\w+\(');
        if (!withMethodPattern.hasMatch(content)) {
          result.addWarning(
            '$className has no with*() configuration methods',
            file: relativePath,
            suggestion:
                'Add methods like withName(), withPrice(), etc. for fluent configuration.',
          );
        }

        // Check for phase transition getters (when, and)
        final hasWhenGetter = RegExp(r'get\s+when\b').hasMatch(content);
        final hasAndGetter = RegExp(r'get\s+and\b').hasMatch(content);

        if (!hasWhenGetter) {
          result.addWarning(
            '$className is missing "when" transition getter',
            file: relativePath,
            suggestion:
                'Add a "get when" getter to transition to the When phase.',
          );
        }
        if (!hasAndGetter) {
          result.addInfo(
            '$className has no "and" getter for chaining given objects',
            file: relativePath,
          );
        }

        // Naming convention: should end with GivenBuilder
        if (!className.endsWith('GivenBuilder')) {
          result.addWarning(
            'Domain object builder "$className" in given/ should end with '
            '"GivenBuilder"',
            file: relativePath,
            suggestion: 'Rename to "${className}GivenBuilder" or similar.',
          );
        }
      }
    }

    if (!hasMainGivenBuilder) {
      result.addError(
        'No class extending GivenBuilder found in builders/given/',
        file: p.join('builders', 'given'),
        suggestion:
            'Create a class like ${_toPascalCase(featureName)}GivenBuilder '
            'extending GivenBuilder.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // When builders validation
  // ---------------------------------------------------------------------------

  void _validateWhenBuilders(
    String featurePath,
    String featureName,
    FeatureValidationResult result,
  ) {
    final whenDir = Directory(p.join(featurePath, 'builders', 'when'));
    if (!whenDir.existsSync()) return;

    final dartFiles = _listDartFiles(whenDir);
    if (dartFiles.isEmpty) {
      result.addError(
        'No Dart files in builders/when/',
        file: p.join('builders', 'when'),
        suggestion: 'Create a WhenBuilder for the $featureName feature.',
      );
      return;
    }

    var hasMainWhenBuilder = false;

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final fileName = p.basename(file.path);
      final relativePath = p.join('builders', 'when', fileName);

      // Check if this is the main WhenBuilder
      final extendsWhenBuilder =
          RegExp(r'class\s+(\w+)\s+extends\s+WhenBuilder\b');
      final whenMatch = extendsWhenBuilder.firstMatch(content);

      if (whenMatch != null) {
        hasMainWhenBuilder = true;
        final className = whenMatch.group(1)!;

        // Naming convention
        final expectedName = '${_toPascalCase(featureName)}WhenBuilder';
        if (className != expectedName) {
          result.addWarning(
            'When builder class "$className" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected class name: "$expectedName".',
          );
        }

        // File naming convention
        final expectedFileName = '${featureName}_when_builder.dart';
        if (fileName != expectedFileName) {
          result.addWarning(
            'When builder file "$fileName" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected file name: "$expectedFileName".',
          );
        }

        // Check for action methods
        final actionMethodPattern = RegExp(r'\w+\s+\w+\(\s*\)\s*(=>|{)');
        if (!actionMethodPattern.hasMatch(content)) {
          result.addWarning(
            'WhenBuilder has no action methods',
            file: relativePath,
            suggestion: 'Add methods like placeOrder(), cancelOrder(), etc. '
                'that return DomainObjectBuilder subclasses.',
          );
        }

        // Check constructor
        if (!content.contains('super.scenario')) {
          result.addWarning(
            'WhenBuilder constructor should use super.scenario',
            file: relativePath,
            suggestion: '$className(super.scenario);',
          );
        }
      }

      // Check if this is a DomainObjectBuilder in when phase
      final extendsDomainBuilder = RegExp(
          r'class\s+(\w+)\s+extends\s+DomainObjectBuilder\s*<\s*NeedsThen\s*>',);
      final domainMatch = extendsDomainBuilder.firstMatch(content);

      if (domainMatch != null) {
        final className = domainMatch.group(1)!;

        // Check for applyToContext override
        final applyPattern = RegExp(r'void\s+applyToContext\s*\(');
        if (!applyPattern.hasMatch(content)) {
          result.addError(
            '$className is missing applyToContext() override',
            file: relativePath,
            suggestion: 'Override applyToContext(TestContext ctx) to execute '
                'the use case logic.',
          );
        }

        // Check for then transition getter
        final hasThenGetter = RegExp(r'get\s+then\b').hasMatch(content);
        if (!hasThenGetter) {
          result.addWarning(
            '$className is missing "then" transition getter',
            file: relativePath,
            suggestion:
                'Add a "get then" getter to transition to the Then phase.',
          );
        }

        // Naming convention: should end with WhenBuilder
        if (!className.endsWith('WhenBuilder')) {
          result.addWarning(
            'Action builder "$className" in when/ should end with "WhenBuilder"',
            file: relativePath,
            suggestion: 'Rename to "${className}WhenBuilder" or similar.',
          );
        }
      }
    }

    if (!hasMainWhenBuilder) {
      result.addError(
        'No class extending WhenBuilder found in builders/when/',
        file: p.join('builders', 'when'),
        suggestion:
            'Create a class like ${_toPascalCase(featureName)}WhenBuilder '
            'extending WhenBuilder.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Then builders validation
  // ---------------------------------------------------------------------------

  void _validateThenBuilders(
    String featurePath,
    String featureName,
    FeatureValidationResult result,
  ) {
    final thenDir = Directory(p.join(featurePath, 'builders', 'then'));
    if (!thenDir.existsSync()) return;

    final dartFiles = _listDartFiles(thenDir);
    if (dartFiles.isEmpty) {
      result.addError(
        'No Dart files in builders/then/',
        file: p.join('builders', 'then'),
        suggestion: 'Create a ThenBuilder for the $featureName feature.',
      );
      return;
    }

    var hasMainThenBuilder = false;

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final fileName = p.basename(file.path);
      final relativePath = p.join('builders', 'then', fileName);

      // Check if this is the main ThenBuilder
      final extendsThenBuilder =
          RegExp(r'class\s+(\w+)\s+extends\s+ThenBuilder\b');
      final thenMatch = extendsThenBuilder.firstMatch(content);

      if (thenMatch != null) {
        hasMainThenBuilder = true;
        final className = thenMatch.group(1)!;

        // Naming convention
        final expectedName = '${_toPascalCase(featureName)}ThenBuilder';
        if (className != expectedName) {
          result.addWarning(
            'Then builder class "$className" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected class name: "$expectedName".',
          );
        }

        // File naming convention
        final expectedFileName = '${featureName}_then_builder.dart';
        if (fileName != expectedFileName) {
          result.addWarning(
            'Then builder file "$fileName" does not follow naming convention',
            file: relativePath,
            suggestion: 'Expected file name: "$expectedFileName".',
          );
        }

        // Check for assertion methods (should/has patterns or methods
        // calling registerAssertion)
        final assertionMethodPattern = RegExp(
          r'(should\w+|has\w+|registerAssertion|addAssertionStep)\s*\(',
        );
        if (!assertionMethodPattern.hasMatch(content)) {
          result.addWarning(
            'ThenBuilder has no assertion methods',
            file: relativePath,
            suggestion:
                'Add assertion methods like shouldSucceed(), shouldFail(), '
                'or methods returning AssertionBuilder subclasses.',
          );
        }

        // Check constructor
        if (!content.contains('super.scenario')) {
          result.addWarning(
            'ThenBuilder constructor should use super.scenario',
            file: relativePath,
            suggestion: '$className(super.scenario);',
          );
        }
      }

      // Check if this is an AssertionBuilder
      final extendsAssertionBuilder =
          RegExp(r'class\s+(\w+)\s+extends\s+AssertionBuilder\b');
      final assertionMatch = extendsAssertionBuilder.firstMatch(content);

      if (assertionMatch != null) {
        final className = assertionMatch.group(1)!;

        // Check for assertion methods (hasX pattern)
        final hasMethodPattern = RegExp(r'\w+\s+has\w+\(');
        if (!hasMethodPattern.hasMatch(content)) {
          result.addWarning(
            '$className has no has*() assertion methods',
            file: relativePath,
            suggestion:
                'Add assertion methods like hasBasePrice(), hasQuantity(), etc.',
          );
        }

        // Check for run() method
        final runPattern = RegExp(r'void\s+run\s*\(\s*\)');
        if (!runPattern.hasMatch(content)) {
          result.addWarning(
            '$className is missing run() method',
            file: relativePath,
            suggestion: 'Add a run() method to execute the scenario.',
          );
        }

        // Naming convention: should end with AssertionBuilder
        if (!className.endsWith('AssertionBuilder')) {
          result.addWarning(
            'Assertion builder "$className" in then/ should end with '
            '"AssertionBuilder"',
            file: relativePath,
            suggestion: 'Rename to a name ending with "AssertionBuilder".',
          );
        }
      }
    }

    if (!hasMainThenBuilder) {
      result.addError(
        'No class extending ThenBuilder found in builders/then/',
        file: p.join('builders', 'then'),
        suggestion:
            'Create a class like ${_toPascalCase(featureName)}ThenBuilder '
            'extending ThenBuilder.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Find the scenario file for a feature.
  ///
  /// Looks for `<feature>_scenario.dart` first, then falls back to
  /// any file containing a class extending FeatureScenario.
  File? _findScenarioFile(String featurePath, String featureName) {
    // Try conventional name first
    final conventionalPath =
        p.join(featurePath, '${featureName}_scenario.dart');
    final conventionalFile = File(conventionalPath);
    if (conventionalFile.existsSync()) return conventionalFile;

    // Fall back to searching for any scenario file in the feature root
    final featureDir = Directory(featurePath);
    final dartFiles = featureDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      if (RegExp(r'extends\s+FeatureScenario\s*<').hasMatch(content)) {
        return file;
      }
    }

    return null;
  }

  /// List all .dart files in a directory.
  List<File> _listDartFiles(Directory dir) {
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  }

  /// Convert a snake_case name to PascalCase.
  String _toPascalCase(String snakeCase) {
    return snakeCase
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
        )
        .join();
  }
}
