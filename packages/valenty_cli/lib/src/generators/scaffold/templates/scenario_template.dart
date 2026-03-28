import '../../../analyzers/model_analyzer.dart';

/// Generates the FeatureScenario entry point file.
String generateScenario({
  required String featureName,
  required String featureSnake,
  required String featurePascal,
  required List<ModelInfo> models,
}) {
  return """import 'package:valenty_test/valenty_test.dart';

import 'builders/given/${featureSnake}_given_builder.dart';

/// Entry point for $featurePascal feature acceptance tests.
///
/// Usage:
/// ```dart
/// ${featurePascal}Scenario('should do something')
///     .given
///     .${models.first.camelCase}()
///         .with${models.first.fields.first.pascalCase}(...)
///     .when
///     .execute()
///         .withParam(...)
///     .then
///     .shouldSucceed();
/// ```
class ${featurePascal}Scenario extends FeatureScenario<${featurePascal}GivenBuilder> {
  ${featurePascal}Scenario(super.description);

  @override
  ${featurePascal}GivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return ${featurePascal}GivenBuilder(scenario);
  }
}
""";
}
