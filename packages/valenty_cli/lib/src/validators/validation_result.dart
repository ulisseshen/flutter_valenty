/// Severity level for a validation finding.
enum ValidationSeverity {
  /// An error that must be fixed for the DSL to work correctly.
  error,

  /// A warning that may indicate a problem but does not prevent usage.
  warning,

  /// An informational note or suggestion.
  info,
}

/// A single validation finding.
class ValidationIssue {
  const ValidationIssue({
    required this.severity,
    required this.message,
    this.file,
    this.suggestion,
  });

  final ValidationSeverity severity;
  final String message;
  final String? file;
  final String? suggestion;

  bool get isError => severity == ValidationSeverity.error;
  bool get isWarning => severity == ValidationSeverity.warning;
}

/// Result of validating a single feature.
class FeatureValidationResult {
  FeatureValidationResult({
    required this.featureName,
    List<ValidationIssue>? issues,
  }) : issues = issues ?? [];

  final String featureName;
  final List<ValidationIssue> issues;

  void addIssue(ValidationIssue issue) => issues.add(issue);

  void addError(String message, {String? file, String? suggestion}) {
    issues.add(
      ValidationIssue(
        severity: ValidationSeverity.error,
        message: message,
        file: file,
        suggestion: suggestion,
      ),
    );
  }

  void addWarning(String message, {String? file, String? suggestion}) {
    issues.add(
      ValidationIssue(
        severity: ValidationSeverity.warning,
        message: message,
        file: file,
        suggestion: suggestion,
      ),
    );
  }

  void addInfo(String message, {String? file}) {
    issues.add(
      ValidationIssue(
        severity: ValidationSeverity.info,
        message: message,
        file: file,
      ),
    );
  }

  bool get hasErrors => issues.any((i) => i.isError);
  bool get hasWarnings => issues.any((i) => i.isWarning);
  bool get isValid => !hasErrors;

  int get errorCount => issues.where((i) => i.isError).length;
  int get warningCount => issues.where((i) => i.isWarning).length;
}

/// Aggregated result for all validated features.
class ValidationResult {
  ValidationResult({List<FeatureValidationResult>? features})
      : features = features ?? [];

  final List<FeatureValidationResult> features;

  void addFeature(FeatureValidationResult feature) => features.add(feature);

  bool get hasErrors => features.any((f) => f.hasErrors);
  bool get hasWarnings => features.any((f) => f.hasWarnings);
  bool get isValid => !hasErrors;

  int get totalErrors =>
      features.fold(0, (sum, f) => sum + f.errorCount);
  int get totalWarnings =>
      features.fold(0, (sum, f) => sum + f.warningCount);
}
