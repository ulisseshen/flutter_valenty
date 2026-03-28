import '../../../analyzers/model_analyzer.dart';

/// Generates the ThenBuilder for a feature.
String generateThenBuilder({
  required String featurePascal,
  required String featureSnake,
  required List<ModelInfo> models,
}) {
  // Generate assertion accessor methods for each model
  final assertionAccessors = StringBuffer();
  for (final model in models) {
    assertionAccessors.writeln(
      '  /// Start a fluent assertion chain for the ${model.camelCase}.',
    );
    assertionAccessors.writeln(
      '  ${model.className}AssertionBuilder ${model.camelCase}() '
      '=> ${model.className}AssertionBuilder(scenario);',
    );
    assertionAccessors.writeln();
  }

  // Generate assertion builder imports
  final assertionImports = StringBuffer();
  for (final model in models) {
    assertionImports.writeln(
      "import '${model.snakeCase}_assertion_builder.dart';",
    );
  }

  return """import 'package:valenty_test/valenty_test.dart';

$assertionImports
/// ThenBuilder for the $featurePascal feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` -- assert the action succeeded
/// - `.shouldFail()` -- assert the action failed
${models.map((m) => '/// - `.${m.camelCase}()` -- fluent assertion builder for ${m.className} properties').join('\n')}
class ${featurePascal}ThenBuilder extends ThenBuilder {
  ${featurePascal}ThenBuilder(super.scenario);

  /// Assert the action succeeded.
  ${featurePascal}ThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      // TODO: Add success assertion logic.
    });
    return ${featurePascal}ThenTerminal(next);
  }

  /// Assert the action failed.
  ${featurePascal}ThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      // TODO: Add failure assertion logic.
    });
    return ${featurePascal}ThenTerminal(next);
  }

$assertionAccessors}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` -- add more assertions
/// - `.run()` -- execute the test
class ${featurePascal}ThenTerminal {
  ${featurePascal}ThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  ${featurePascal}AndThenBuilder get and => ${featurePascal}AndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the $featurePascal feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class ${featurePascal}AndThenBuilder extends AndThenBuilder {
  ${featurePascal}AndThenBuilder(super.scenario);

${models.map((m) => '  /// Start a fluent assertion chain for the ${m.camelCase}.\n  ${m.className}AssertionBuilder ${m.camelCase}() => ${m.className}AssertionBuilder(scenario);').join('\n\n')}
}
""";
}
