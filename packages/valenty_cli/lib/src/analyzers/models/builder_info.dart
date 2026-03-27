import 'method_info.dart';

/// The kind of builder, derived from its superclass.
enum BuilderKind {
  givenBuilder,
  whenBuilder,
  thenBuilder,
  domainObjectBuilder,
  assertionBuilder,
  andThenBuilder,
  featureScenario,
}

/// Information about a single builder class extracted from source.
class BuilderInfo {
  const BuilderInfo({
    required this.className,
    required this.kind,
    required this.filePath,
    required this.methods,
    this.superclass = '',
  });

  /// The class name (e.g. `OrderGivenBuilder`).
  final String className;

  /// What kind of builder this is.
  final BuilderKind kind;

  /// Absolute path to the source file.
  final String filePath;

  /// The declared superclass name.
  final String superclass;

  /// Public methods declared in this builder.
  final List<MethodInfo> methods;

  /// A human-readable label for the builder kind.
  String get kindLabel {
    switch (kind) {
      case BuilderKind.givenBuilder:
        return 'GivenBuilder';
      case BuilderKind.whenBuilder:
        return 'WhenBuilder';
      case BuilderKind.thenBuilder:
        return 'ThenBuilder';
      case BuilderKind.domainObjectBuilder:
        return 'DomainObjectBuilder';
      case BuilderKind.assertionBuilder:
        return 'AssertionBuilder';
      case BuilderKind.andThenBuilder:
        return 'AndThenBuilder';
      case BuilderKind.featureScenario:
        return 'FeatureScenario';
    }
  }

  /// The phase this builder belongs to (`given`, `when`, `then`).
  String get phase {
    switch (kind) {
      case BuilderKind.givenBuilder:
      case BuilderKind.domainObjectBuilder:
        return 'given';
      case BuilderKind.whenBuilder:
        return 'when';
      case BuilderKind.thenBuilder:
      case BuilderKind.assertionBuilder:
      case BuilderKind.andThenBuilder:
        return 'then';
      case BuilderKind.featureScenario:
        return 'scenario';
    }
  }

  Map<String, dynamic> toJson() => {
        'className': className,
        'kind': kindLabel,
        'phase': phase,
        'file': filePath,
        if (superclass.isNotEmpty) 'superclass': superclass,
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}
