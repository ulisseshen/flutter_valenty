import 'builder_info.dart';

/// Aggregated information about a single Valenty feature.
class FeatureInfo {
  const FeatureInfo({
    required this.name,
    required this.directoryPath,
    required this.scenarioClass,
    required this.builders,
  });

  /// The feature name, derived from the directory name (e.g. `order`).
  final String name;

  /// Absolute path to the feature directory.
  final String directoryPath;

  /// The scenario class name (e.g. `OrderScenario`), or empty if not found.
  final String scenarioClass;

  /// All builders discovered for this feature.
  final List<BuilderInfo> builders;

  /// Builders filtered by phase.
  List<BuilderInfo> buildersForPhase(String phase) =>
      builders.where((b) => b.phase == phase).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'directory': directoryPath,
        'scenarioClass': scenarioClass,
        'builders': builders.map((b) => b.toJson()).toList(),
      };
}
