import 'package:valenty_dsl/valenty_dsl.dart';

import 'builders/given/scaffold_given_builder.dart';

/// Entry point for Scaffold feature acceptance tests.
///
/// Usage:
/// ```dart
/// ScaffoldScenario('should generate builder tree for a single model')
///     .given
///     .project()
///         .withName('my_app')
///     .and
///     .modelFile()
///         .withClassName('Product')
///         .withFields({'name': 'String', 'unitPrice': 'double'})
///         .atPath('lib/models/product.dart')
///     .when
///     .runScaffold()
///         .withFeatureName('order')
///         .withModelPaths(['lib/models/product.dart'])
///     .then
///     .shouldSucceed();
/// ```
class ScaffoldScenario extends FeatureScenario<ScaffoldGivenBuilder> {
  ScaffoldScenario(super.description);

  @override
  ScaffoldGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return ScaffoldGivenBuilder(scenario);
  }
}
