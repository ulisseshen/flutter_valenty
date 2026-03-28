/// Available test channel types for multi-channel testing.
enum ChannelType {
  /// UI-based interactions (e.g., Flutter widgets, web UI).
  ui,

  /// API-based interactions (e.g., REST, GraphQL).
  api,

  /// CLI-based interactions.
  cli,
}

/// Marks a test class as supporting specific channels.
///
/// Example:
/// ```dart
/// @ChannelAnnotation({ChannelType.ui, ChannelType.api})
/// class OrderAcceptanceTest { ... }
/// ```
class ChannelAnnotation {
  /// Create a channel annotation with the given [types].
  const ChannelAnnotation(this.types);

  /// The set of channel types this test supports.
  final Set<ChannelType> types;
}

/// Marks a test as belonging to a specific test pyramid level.
class PyramidLevel {
  /// Create a pyramid level annotation with the given [level] name.
  const PyramidLevel(this.level);

  /// The test pyramid level name (e.g., 'unit', 'component', 'acceptance').
  final String level;
}

/// Marks a test class as testing a specific feature.
class Feature {
  /// Create a feature annotation with the given [name].
  const Feature(this.name);

  /// The feature name this test class covers.
  final String name;
}
