import 'package:valenty_dsl/valenty_dsl.dart';

import 'model_file_given_builder.dart';
import 'project_given_builder.dart';

/// GivenBuilder for the Scaffold feature.
///
/// Provides domain objects available in the Given phase:
/// - `.project()` — set up a temporary project directory
/// - `.modelFile()` — create a model file in the temp project
class ScaffoldGivenBuilder extends GivenBuilder {
  ScaffoldGivenBuilder(super.scenario);

  /// Set up a temporary project directory.
  ProjectGivenBuilder project() => ProjectGivenBuilder(scenario);

  /// Create a model file in the temp project.
  ModelFileGivenBuilder modelFile() => ModelFileGivenBuilder(scenario);
}
