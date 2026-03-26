import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for the And phase after Then (additional assertions).
///
/// Subclass this to define domain-specific assertion methods
/// available after `.and` in the Then phase.
abstract class AndThenBuilder {
  AndThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ScenarioBuilder<ReadyToRun> registerAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.and,
        action: action,
        description: description,
      ),
    );
  }
}
