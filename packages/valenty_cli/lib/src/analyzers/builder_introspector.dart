import 'dart:io';

import 'package:path/path.dart' as p;

import 'models/builder_info.dart';
import 'models/feature_info.dart';
import 'models/method_info.dart';

/// Scans a project for Valenty builders and extracts structural metadata.
///
/// Looks for classes extending the core DSL base classes:
/// `GivenBuilder`, `WhenBuilder`, `ThenBuilder`,
/// `DomainObjectBuilder`, `AssertionBuilder`, `AndThenBuilder`,
/// and `FeatureScenario`.
class BuilderIntrospector {
  /// The base class names we recognise, mapped to their [BuilderKind].
  static const _superclassMap = {
    'GivenBuilder': BuilderKind.givenBuilder,
    'WhenBuilder': BuilderKind.whenBuilder,
    'ThenBuilder': BuilderKind.thenBuilder,
    'DomainObjectBuilder': BuilderKind.domainObjectBuilder,
    'AssertionBuilder': BuilderKind.assertionBuilder,
    'AndThenBuilder': BuilderKind.andThenBuilder,
    'FeatureScenario': BuilderKind.featureScenario,
  };

  /// Regex that matches `class Foo extends Bar` or
  /// `class Foo extends Bar<Baz>`.
  /// Supports generic superclasses with nested angle brackets.
  static final _classPattern = RegExp(
    r'class\s+(\w+)\s+extends\s+(\w+)(?:<[\w<>,?\s]+>)?',
  );

  /// Regex that matches public instance methods that return a concrete type.
  ///
  /// Captures: returnType, methodName, parameters.
  /// Excludes overrides of framework methods (`applyToContext`, etc.).
  /// Supports multiline method signatures via `[\s\S]*?` instead of `[^)]*`.
  /// Supports generic return types with nesting (e.g. `Future<Order?>`).
  static final _methodPattern = RegExp(
    r'^\s+([\w]+(?:<[\w<>,?\s]+>)?\??)\s+'
    r'(with\w+|has\w+|should\w+|[a-z]\w*)'
    r'\(([\s\S]*?)\)',
    multiLine: true,
  );

  /// Scans the project at [projectPath] for Valenty feature directories.
  ///
  /// Convention: features live under `test/valenty/features/<name>/`.
  List<FeatureInfo> inspect(String projectPath) {
    final featuresDir = Directory(
      p.join(projectPath, 'test', 'valenty', 'features'),
    );

    if (!featuresDir.existsSync()) {
      return [];
    }

    final features = <FeatureInfo>[];
    for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
      final feature = _inspectFeature(featureDir);
      if (feature != null) {
        features.add(feature);
      }
    }

    features.sort((a, b) => a.name.compareTo(b.name));
    return features;
  }

  FeatureInfo? _inspectFeature(Directory featureDir) {
    final dartFiles = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (dartFiles.isEmpty) return null;

    final builders = <BuilderInfo>[];
    var scenarioClass = '';

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final extracted = _extractBuilders(content, file.path);

      for (final builder in extracted) {
        if (builder.kind == BuilderKind.featureScenario) {
          scenarioClass = builder.className;
        }
        builders.add(builder);
      }
    }

    if (builders.isEmpty) return null;

    return FeatureInfo(
      name: p.basename(featureDir.path),
      directoryPath: featureDir.path,
      scenarioClass: scenarioClass,
      builders: builders,
    );
  }

  List<BuilderInfo> _extractBuilders(String content, String filePath) {
    final results = <BuilderInfo>[];

    for (final match in _classPattern.allMatches(content)) {
      final className = match.group(1)!;
      final superclass = match.group(2)!;

      final kind = _superclassMap[superclass];
      if (kind == null) continue;

      final methods = _extractMethods(content, className, kind);

      results.add(
        BuilderInfo(
          className: className,
          kind: kind,
          filePath: filePath,
          superclass: superclass,
          methods: methods,
        ),
      );
    }

    return results;
  }

  List<MethodInfo> _extractMethods(
    String content,
    String className,
    BuilderKind kind,
  ) {
    final methods = <MethodInfo>[];

    // Skip framework-internal methods.
    const excludedMethods = {
      'applyToContext',
      'createGivenBuilder',
      'registerAssertion',
      'addAssertionStep',
      'finalizeStep',
      'run',
    };

    for (final match in _methodPattern.allMatches(content)) {
      final returnType = match.group(1)!;
      final methodName = match.group(2)!;
      final rawParams = match.group(3)!.trim();

      if (excludedMethods.contains(methodName)) continue;
      if (methodName.startsWith('_')) continue;

      final parameters = rawParams.isEmpty
          ? <String>[]
          : rawParams
              .split(',')
              .map((p) => p.trim().replaceAll(RegExp(r'\s+'), ' '))
              .where((p) => p.isNotEmpty)
              .toList();

      methods.add(
        MethodInfo(
          name: methodName,
          returnType: returnType,
          parameters: parameters,
        ),
      );
    }

    return methods;
  }
}
