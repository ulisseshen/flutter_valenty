import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for the Then phase of a scenario.
///
/// Subclass this to define domain-specific assertion methods.
/// Methods that directly assert (like `shouldSucceed()`) register
/// an assertion and return a terminal object. Methods that start
/// a fluent assertion chain (like `order()`) return an
/// [AssertionBuilder] subclass.
///
/// Example:
/// ```dart
/// class OrderThenBuilder extends ThenBuilder {
///   OrderThenBuilder(super.scenario);
///
///   ScenarioBuilder<ReadyToRun> shouldSucceed() {
///     return registerAssertion((ctx) {
///       expect(ctx.get<bool>('success'), isTrue);
///     });
///   }
///
///   OrderAssertionBuilder order() {
///     return OrderAssertionBuilder(scenario);
///   }
/// }
/// ```
abstract class ThenBuilder {
  /// Create a ThenBuilder wrapping the scenario in [ReadyToRun] state.
  ThenBuilder(this._scenario);

  final ScenarioBuilder<ReadyToRun> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<ReadyToRun> get scenario => _scenario;

  /// Register an assertion action and return the scenario
  /// in [ReadyToRun] state.
  ///
  /// Use this helper in subclass methods like `shouldSucceed()`.
  ScenarioBuilder<ReadyToRun> registerAssertion(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    return _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }
}
