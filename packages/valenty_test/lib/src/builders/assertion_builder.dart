import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for fluent assertion builders.
///
/// Assertion builders are used in the Then phase to verify outcomes
/// with fluent `.hasX()` methods. Each `.hasX()` method calls
/// [addAssertionStep] to register the assertion AND returns `this`
/// (the concrete subclass) for further chaining.
///
/// The subclass also defines `.and` and `.run()` getters to transition
/// out of the assertion chain.
///
/// ## Example
///
/// ```dart
/// class OrderAssertionBuilder extends AssertionBuilder {
///   OrderAssertionBuilder(super.scenario);
///
///   OrderAssertionBuilder hasBasePrice(double expected) {
///     addAssertionStep((ctx) {
///       final order = ctx.get<Order>('order');
///       expect(order.basePrice, equals(expected));
///     });
///     return this;
///   }
///
///   void run() => currentScenario.run();
/// }
/// ```
abstract class AssertionBuilder {
  /// Create an assertion builder wrapping the scenario in [ReadyToRun] state.
  AssertionBuilder(this._scenario);

  ScenarioBuilder<ReadyToRun> _scenario;

  /// Register an assertion step.
  ///
  /// Call this from `.hasX()` methods. The assertion is recorded as a
  /// step in the scenario.
  void addAssertionStep(
    dynamic Function(TestContext ctx) action, {
    String? description,
  }) {
    _scenario = _scenario.appendStep(
      StepRecord(
        phase: StepPhase.then,
        action: action,
        description: description,
      ),
    );
  }

  /// Get the current scenario builder with all assertions registered.
  ///
  /// Use this in `.and` and `.run()` implementations.
  ScenarioBuilder<ReadyToRun> get currentScenario => _scenario;
}
