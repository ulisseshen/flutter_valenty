import 'dart:io';

import 'package:path/path.dart' as p;

import 'models/builder_info.dart';
import 'models/feature_info.dart';
import 'models/method_info.dart';

/// A snapshot of the current project state produced by [ProjectIntrospector].
class ProjectSnapshot {
  const ProjectSnapshot({
    required this.features,
    required this.domainModels,
  });

  /// Empty snapshot with no features or domain models.
  static const empty = ProjectSnapshot(features: [], domainModels: []);

  /// Discovered Valenty features with their builders and methods.
  final List<FeatureInfo> features;

  /// Domain model classes found in `lib/`.
  final List<DomainModelInfo> domainModels;

  /// Whether this snapshot contains any meaningful data.
  bool get hasData => features.isNotEmpty || domainModels.isNotEmpty;
}

/// Information about a domain model class found in `lib/`.
class DomainModelInfo {
  const DomainModelInfo({
    required this.className,
    required this.filePath,
    required this.properties,
  });

  /// The class name (e.g. `Product`).
  final String className;

  /// Relative path from project root to the source file.
  final String filePath;

  /// Named properties declared in the class.
  final List<DomainPropertyInfo> properties;
}

/// A single property on a domain model.
class DomainPropertyInfo {
  const DomainPropertyInfo({
    required this.name,
    required this.type,
  });

  /// The property name (e.g. `unitPrice`).
  final String name;

  /// The declared type (e.g. `double`).
  final String type;
}

/// Scans a Valenty project and produces a [ProjectSnapshot].
///
/// Uses regex-based parsing to extract features, builders, methods,
/// and domain models without requiring the Dart analyzer.
class ProjectIntrospector {
  const ProjectIntrospector();

  // ── Regex patterns ──────────────────────────────────────────────────

  /// Matches class declarations: `class Foo extends Bar<Baz> {`
  /// Supports generic superclasses with nested angle brackets.
  static final _classDeclarationRe = RegExp(
    r'class\s+(\w+)\s+extends\s+([\w]+(?:<[\w<>,?\s]+>)?)\s*\{',
  );

  /// Matches public method declarations (non-getter, non-override).
  /// e.g. `ProductGivenBuilder withName(String name) {`
  ///
  /// Uses `[\s\S]*?` instead of `[^)]*` to support multiline method
  /// signatures where parameters span multiple lines.
  static final _methodRe = RegExp(
    r'^\s+([\w]+(?:<[\w<>,?\s]+>)?\??)\s+(\w+)\s*\(([\s\S]*?)\)\s*[\{=]',
    multiLine: true,
  );

  /// Matches getter declarations: `OrderWhenBuilder get when {`
  static final _getterRe = RegExp(
    r'^\s+(\w[\w<>?]*)\s+get\s+(\w+)\s*[\{=]',
    multiLine: true,
  );

  /// Matches `final Type name;` property declarations.
  /// Supports generics with nesting (e.g. `Map<String, List<int>>`),
  /// nullable types, and fields with default values.
  static final _finalFieldRe = RegExp(
    r'^\s+final\s+([\w]+(?:<[\w<>,?\s]+>)?\??)\s+(\w+)\s*[;=]',
    multiLine: true,
  );

  /// Matches `required this.name` in constructor parameters.
  static final _requiredThisRe = RegExp(
    r'required\s+this\.(\w+)',
  );

  // ── Public API ──────────────────────────────────────────────────────

  /// Introspect the project at [projectPath] and return a snapshot.
  ///
  /// Returns [ProjectSnapshot.empty] if introspection fails or finds nothing.
  ProjectSnapshot introspect(String projectPath) {
    try {
      final features = _scanFeatures(projectPath);
      final domainModels = _scanDomainModels(projectPath);
      return ProjectSnapshot(features: features, domainModels: domainModels);
    } catch (_) {
      return ProjectSnapshot.empty;
    }
  }

  // ── Feature scanning ───────────────────────────────────────────────

  List<FeatureInfo> _scanFeatures(String projectPath) {
    final featuresDir = Directory(
      p.join(projectPath, 'test', 'valenty', 'features'),
    );

    if (!featuresDir.existsSync()) return [];

    final features = <FeatureInfo>[];

    for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
      final featureName = p.basename(featureDir.path);
      final builders = <BuilderInfo>[];
      var scenarioClass = '';

      // Scan all .dart files in the feature directory tree
      final dartFiles = featureDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final extracted = _extractBuildersFromSource(content, file.path);

        for (final builder in extracted) {
          builders.add(builder);
          if (builder.kind == BuilderKind.featureScenario) {
            scenarioClass = builder.className;
          }
        }
      }

      if (builders.isNotEmpty) {
        features.add(FeatureInfo(
          name: featureName,
          directoryPath: featureDir.path,
          scenarioClass: scenarioClass,
          builders: builders,
        ),);
      }
    }

    return features;
  }

  List<BuilderInfo> _extractBuildersFromSource(
    String source,
    String filePath,
  ) {
    final results = <BuilderInfo>[];

    for (final match in _classDeclarationRe.allMatches(source)) {
      final className = match.group(1)!;
      final superclass = match.group(2)!;
      final kind = _classifyBuilder(superclass);

      if (kind == null) continue;

      // Extract the class body (rough heuristic: from match to end of file)
      final classStart = match.start;
      final classBody = _extractClassBody(source, classStart);

      final methods = _extractMethods(classBody, className);

      results.add(BuilderInfo(
        className: className,
        kind: kind,
        filePath: filePath,
        superclass: superclass,
        methods: methods,
      ),);
    }

    return results;
  }

  BuilderKind? _classifyBuilder(String superclass) {
    if (superclass.startsWith('FeatureScenario')) {
      return BuilderKind.featureScenario;
    }
    if (superclass == 'GivenBuilder') return BuilderKind.givenBuilder;
    if (superclass == 'WhenBuilder') return BuilderKind.whenBuilder;
    if (superclass == 'ThenBuilder') return BuilderKind.thenBuilder;
    if (superclass == 'AssertionBuilder') return BuilderKind.assertionBuilder;
    if (superclass == 'AndThenBuilder') return BuilderKind.andThenBuilder;
    if (superclass.startsWith('DomainObjectBuilder')) {
      return BuilderKind.domainObjectBuilder;
    }
    return null;
  }

  /// Extract the body of a class starting at [classStart].
  ///
  /// Uses brace-counting to find the matching closing brace.
  String _extractClassBody(String source, int classStart) {
    var braceCount = 0;
    var foundFirst = false;
    var bodyStart = classStart;

    for (var i = classStart; i < source.length; i++) {
      if (source[i] == '{') {
        if (!foundFirst) {
          foundFirst = true;
          bodyStart = i;
        }
        braceCount++;
      } else if (source[i] == '}') {
        braceCount--;
        if (braceCount == 0 && foundFirst) {
          return source.substring(bodyStart, i + 1);
        }
      }
    }

    // If we can't find the end, return from bodyStart to end of source
    return source.substring(bodyStart);
  }

  List<MethodInfo> _extractMethods(String classBody, String className) {
    final methods = <MethodInfo>[];
    final seenNames = <String>{};

    // Skip internal/private methods and overrides for the public API listing.
    // We want: withX(), hasX(), domain object factory methods, shouldX().
    for (final match in _methodRe.allMatches(classBody)) {
      final returnType = match.group(1)!;
      final methodName = match.group(2)!;
      final paramsRaw = match.group(3)!.trim();

      // Skip private, constructor-like, or override methods
      if (methodName.startsWith('_')) continue;
      if (methodName == 'applyToContext') continue;
      if (methodName == 'createGivenBuilder') continue;
      if (methodName == className) continue;

      if (seenNames.contains(methodName)) continue;
      seenNames.add(methodName);

      final parameters = paramsRaw.isEmpty ? <String>[] : [paramsRaw];

      methods.add(MethodInfo(
        name: methodName,
        returnType: returnType,
        parameters: parameters,
      ),);
    }

    // Also extract getters (when, and, then)
    for (final match in _getterRe.allMatches(classBody)) {
      final returnType = match.group(1)!;
      final getterName = match.group(2)!;

      if (getterName.startsWith('_')) continue;
      if (seenNames.contains(getterName)) continue;
      seenNames.add(getterName);

      methods.add(MethodInfo(
        name: getterName,
        returnType: returnType,
      ),);
    }

    return methods;
  }

  // ── Domain model scanning ──────────────────────────────────────────

  List<DomainModelInfo> _scanDomainModels(String projectPath) {
    final libDir = Directory(p.join(projectPath, 'lib'));

    if (!libDir.existsSync()) return [];

    final models = <DomainModelInfo>[];

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final relativePath = p.relative(file.path, from: projectPath);
      final extracted = _extractDomainModels(content, relativePath);
      models.addAll(extracted);
    }

    return models;
  }

  List<DomainModelInfo> _extractDomainModels(
    String source,
    String filePath,
  ) {
    final models = <DomainModelInfo>[];

    // Strip comments to avoid false matches from commented-out code.
    final cleanSource = _stripComments(source);

    // Detect enum names so we can skip them.
    final enumRe = RegExp(r'enum\s+(\w+)\s*\{');
    final enumNames =
        enumRe.allMatches(cleanSource).map((m) => m.group(1)!).toSet();

    // Match classes (including abstract) but not enums
    final classRe = RegExp(r'(?:abstract\s+)?class\s+(\w+)\s*(?:\{|extends|implements|with)');
    for (final match in classRe.allMatches(cleanSource)) {
      final className = match.group(1)!;

      // Skip enums, builder-related classes, generated code, etc.
      if (enumNames.contains(className)) continue;
      if (className.endsWith('Builder') ||
          className.endsWith('Scenario') ||
          className.endsWith('Runner') ||
          className.endsWith('State') ||
          className.startsWith('_')) {
        continue;
      }

      // Find the opening brace for this class
      final afterMatch = cleanSource.indexOf('{', match.start);
      if (afterMatch == -1) continue;

      final classBody = _extractClassBody(cleanSource, match.start);
      final properties = _extractProperties(classBody, cleanSource, match.start);

      // Only include classes that have properties (domain models)
      if (properties.isNotEmpty) {
        models.add(DomainModelInfo(
          className: className,
          filePath: filePath,
          properties: properties,
        ),);
      }
    }

    return models;
  }

  List<DomainPropertyInfo> _extractProperties(
    String classBody,
    String fullSource,
    int classStart,
  ) {
    final properties = <DomainPropertyInfo>[];
    final seenNames = <String>{};

    // Strategy 1: Look for `final Type name;` declarations
    for (final match in _finalFieldRe.allMatches(classBody)) {
      final type = match.group(1)!.trim();
      final name = match.group(2)!;

      // Skip private fields
      if (name.startsWith('_')) continue;
      if (seenNames.contains(name)) continue;

      // Skip static fields — check if the line containing this match
      // starts with `static`.
      final lineStart = classBody.lastIndexOf('\n', match.start) + 1;
      final linePrefix = classBody.substring(lineStart, match.start);
      if (linePrefix.contains('static')) continue;

      seenNames.add(name);
      properties.add(DomainPropertyInfo(
        name: name,
        type: _normalizeType(type),
      ),);
    }

    // Strategy 2: If no final fields found, look for `required this.x`
    // in constructor and try to infer types from the constructor signature.
    if (properties.isEmpty) {
      for (final match in _requiredThisRe.allMatches(classBody)) {
        final name = match.group(1)!;
        if (name.startsWith('_')) continue;
        if (seenNames.contains(name)) continue;
        seenNames.add(name);

        properties.add(DomainPropertyInfo(name: name, type: 'dynamic'));
      }
    }

    return properties;
  }

  /// Strip single-line and multi-line comments from source code.
  String _stripComments(String source) {
    var result = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    result = result.replaceAll(RegExp(r'//[^\n]*'), '');
    return result;
  }

  /// Normalize whitespace in a type string.
  String _normalizeType(String type) {
    return type
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('< ', '<')
        .replaceAll(' >', '>')
        .replaceAll(' ,', ',')
        .replaceAll(', ', ', ')
        .trim();
  }
}
