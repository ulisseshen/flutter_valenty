import '../../../analyzers/model_analyzer.dart';

/// Generates an AssertionBuilder for a single model.
String generateAssertionBuilder({
  required String featurePascal,
  required String featureSnake,
  required ModelInfo model,
  required String modelImportPath,
}) {
  final className = '${model.className}AssertionBuilder';

  // Generate has*() methods for each field
  final hasMethods = StringBuffer();
  for (final field in model.fields) {
    hasMethods.writeln(
      '  /// Assert the ${model.camelCase} has the expected ${field.name}.',
    );
    hasMethods.writeln(
      '  $className has${field.pascalCase}(${field.type} expected) {',
    );
    hasMethods.writeln('    addAssertionStep((ctx) {');
    hasMethods.writeln(
      "      final ${model.camelCase} = ctx.get<${model.className}>('${model.camelCase}');",
    );
    hasMethods.writeln('      expect(');
    hasMethods.writeln('        ${model.camelCase}.${field.name},');
    hasMethods.writeln('        equals(expected),');
    hasMethods
        .writeln("        reason: 'Expected ${field.name} to be \$expected',");
    hasMethods.writeln('      );');
    hasMethods.writeln('    });');
    hasMethods.writeln('    return this;');
    hasMethods.writeln('  }');
    hasMethods.writeln();
  }

  return """import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '$modelImportPath';
import '${featureSnake}_then_builder.dart';

/// Fluent assertion builder for ${model.className} properties.
///
/// Available assertions:
${model.fields.map((f) => '/// - `.has${f.pascalCase}(${f.type})` -- assert the ${f.name}').join('\n')}
///
/// Chain with:
/// - `.and` -- add more assertions
/// - `.run()` -- execute the test
class $className extends AssertionBuilder {
  $className(super.scenario);

$hasMethods  /// Add more assertions.
  ${featurePascal}AndThenBuilder get and => ${featurePascal}AndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
""";
}
