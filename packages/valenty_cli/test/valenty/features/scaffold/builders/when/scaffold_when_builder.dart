import 'package:valenty_dsl/valenty_dsl.dart';

import 'run_scaffold_when_builder.dart';

/// WhenBuilder for the Scaffold feature.
///
/// Provides use cases available in the When phase:
/// - `.runScaffold()` — execute the scaffold generator
class ScaffoldWhenBuilder extends WhenBuilder {
  ScaffoldWhenBuilder(super.scenario);

  /// Trigger the scaffold generation.
  RunScaffoldWhenBuilder runScaffold() => RunScaffoldWhenBuilder(scenario);
}
