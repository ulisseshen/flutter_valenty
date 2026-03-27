import '../../../analyzers/model_analyzer.dart';

/// Generates the GivenBuilder for a feature.
String generateGivenBuilder({
  required String featurePascal,
  required String featureSnake,
  required List<ModelInfo> models,
}) {
  final imports = StringBuffer();
  for (final model in models) {
    imports.writeln("import '${model.snakeCase}_given_builder.dart';");
  }

  final methods = StringBuffer();
  for (final model in models) {
    methods.writeln('  /// Set up a ${model.className} in the test context.');
    methods.writeln(
      '  ${model.className}GivenBuilder ${model.camelCase}() '
      '=> ${model.className}GivenBuilder(scenario);',
    );
    methods.writeln();
  }

  return """import 'package:valenty_dsl/valenty_dsl.dart';

$imports
/// GivenBuilder for the $featurePascal feature.
///
/// Provides domain objects available in the Given phase:
${models.map((m) => '/// - `.${m.camelCase}()` -- set up a ${m.className}').join('\n')}
class ${featurePascal}GivenBuilder extends GivenBuilder {
  ${featurePascal}GivenBuilder(super.scenario);

$methods}
""";
}
