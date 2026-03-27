import '../../../analyzers/model_analyzer.dart';

/// Generates the WhenBuilder for a feature.
String generateWhenBuilder({
  required String featurePascal,
  required String featureSnake,
  required List<ModelInfo> models,
}) {
  final actionName = 'execute$featurePascal';
  final actionBuilderName = 'Execute${featurePascal}WhenBuilder';

  return """import 'package:valenty_dsl/valenty_dsl.dart';

import '${featureSnake}_action_builder.dart';

/// WhenBuilder for the $featurePascal feature.
///
/// Provides use cases available in the When phase:
/// - `.$actionName()` -- execute the $featurePascal action
class ${featurePascal}WhenBuilder extends WhenBuilder {
  ${featurePascal}WhenBuilder(super.scenario);

  /// Trigger the "$actionName" use case.
  $actionBuilderName $actionName() => $actionBuilderName(scenario);
}
""";
}

/// Generates the action DomainObjectBuilder for the When phase.
String generateActionBuilder({
  required String featurePascal,
  required String featureSnake,
  required List<ModelInfo> models,
}) {
  final actionBuilderName = 'Execute${featurePascal}WhenBuilder';

  return """import 'package:valenty_dsl/valenty_dsl.dart';

import '../then/${featureSnake}_then_builder.dart';

/// Builder for the "execute $featurePascal" use case.
///
/// Available methods:
/// - `.then` -- transition to Then phase
class $actionBuilderName extends DomainObjectBuilder<NeedsThen> {
  $actionBuilderName(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  @override
  void applyToContext(TestContext ctx) {
    // TODO: Implement the action logic.
    // Retrieve domain objects from ctx, perform the use case,
    // and store the result back in ctx.
  }

  /// Transition to Then phase.
  ${featurePascal}ThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return ${featurePascal}ThenBuilder(next);
  }
}
""";
}
