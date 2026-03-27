import 'package:mason_logger/mason_logger.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'package:valenty_cli/src/generators/scaffold/scaffold_generator.dart';
import '../then/scaffold_then_builder.dart';

/// Builder for the "run scaffold" use case.
///
/// Available methods:
/// - `.withFeatureName(String)` — set the feature name
/// - `.withModelPaths(List<String>)` — set model file paths
/// - `.then` — transition to Then phase
class RunScaffoldWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  RunScaffoldWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _featureName = 'feature';
  List<String>? _modelPaths;

  RunScaffoldWhenBuilder withFeatureName(String featureName) {
    _featureName = featureName;
    return this;
  }

  RunScaffoldWhenBuilder withModelPaths(List<String> modelPaths) {
    _modelPaths = modelPaths;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // Configuration is stored; actual generation happens in the async step.
    // This is a no-op because generate() is async and needs a Future-returning
    // action. See the custom `then` getter below.
  }

  /// Transition to Then phase.
  ///
  /// Registers an async step that runs the scaffold generator,
  /// since [ScaffoldGenerator.generate] returns a Future.
  ScaffoldThenBuilder get then {
    // Capture config before finalizing
    final featureName = _featureName;
    final modelPathsOverride = _modelPaths;

    final finalized = finalizeStep();
    final withAsyncAction = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final projectPath = ctx.get<String>('projectPath');

          // Use explicitly provided model paths, or fall back to context
          final modelPaths = modelPathsOverride ??
              (ctx.has('modelPaths')
                  ? ctx.get<List<String>>('modelPaths')
                  : <String>[]);

          ctx.set('featureName', featureName);
          ctx.set('scaffoldModelPaths', modelPaths);

          final logger = Logger(level: Level.quiet);
          final generator = ScaffoldGenerator(logger: logger);

          try {
            await generator.generate(
              featureName: featureName,
              modelPaths: modelPaths,
              projectPath: projectPath,
            );
            ctx.set('scaffoldSuccess', true);
            ctx.set('scaffoldError', '');
          } catch (e) {
            ctx.set('scaffoldSuccess', false);
            ctx.set('scaffoldError', e.toString());
          }
        },
      ),
    );

    final next = withAsyncAction.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return ScaffoldThenBuilder(next);
  }
}
