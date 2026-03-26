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
  const ChannelAnnotation(this.types);

  /// The set of channel types this test supports.
  final Set<ChannelType> types;
}

/// Marks a test as belonging to a specific test pyramid level.
class PyramidLevel {
  const PyramidLevel(this.level);
  final String level;
}

/// Marks a test class as testing a specific feature.
class Feature {
  const Feature(this.name);
  final String name;
}
