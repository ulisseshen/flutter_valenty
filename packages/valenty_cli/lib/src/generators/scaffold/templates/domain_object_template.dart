import '../../../analyzers/model_analyzer.dart';

/// Generates a DomainObjectBuilder for a single model in the Given phase.
String generateDomainObjectBuilder({
  required String featurePascal,
  required String featureSnake,
  required ModelInfo model,
  required String modelImportPath,
}) {
  final className = '${model.className}GivenBuilder';

  // Generate private fields with defaults
  final fields = StringBuffer();
  for (final field in model.fields) {
    fields.writeln('  ${field.type} _${field.name} = ${field.defaultValue};');
  }

  // Generate with*() methods
  final withMethods = StringBuffer();
  for (final field in model.fields) {
    withMethods.writeln(
        '  $className with${field.pascalCase}(${field.type} ${field.name}) {',);
    withMethods.writeln('    _${field.name} = ${field.name};');
    withMethods.writeln('    return this;');
    withMethods.writeln('  }');
    withMethods.writeln();
  }

  // Generate constructor args for applyToContext
  final constructorArgs =
      model.fields.map((f) => '${f.name}: _${f.name}').join(', ');

  return """import 'package:valenty_test/valenty_test.dart';

import '$modelImportPath';
import '../when/${featureSnake}_when_builder.dart';
import '${featureSnake}_given_builder.dart';

/// Builder for setting up a ${model.className} in the Given phase.
///
/// Available methods:
${model.fields.map((f) => '/// - `.with${f.pascalCase}(${f.type})` -- set ${f.name}').join('\n')}
/// - `.when` -- transition to When phase
/// - `.and` -- add more domain objects
class $className extends DomainObjectBuilder<NeedsWhen> {
  $className(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

$fields
$withMethods  @override
  void applyToContext(TestContext ctx) {
    ctx.set('${model.camelCase}', ${model.className}($constructorArgs));
  }

  /// Transition to When phase.
  ${featurePascal}WhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return ${featurePascal}WhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  ${featurePascal}GivenBuilder get and {
    final finalized = finalizeStep();
    return ${featurePascal}GivenBuilder(finalized);
  }
}
""";
}
