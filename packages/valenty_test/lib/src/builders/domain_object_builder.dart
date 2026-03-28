import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_context.dart';

/// Base class for fluent domain object builders.
///
/// Domain object builders are used in the Given and When phases to
/// configure preconditions and actions with fluent `.withX()` methods.
///
/// The type parameter [TParent] is the phantom type of the scenario
/// state that this builder operates within:
/// - `NeedsWhen` for Given-phase builders
/// - `NeedsThen` for When-phase builders
///
/// ## How it works
///
/// 1. Each `.withX()` method stores a value and returns `this` for chaining.
/// 2. The subclass overrides [applyToContext] to write built values to context.
/// 3. The subclass defines transition getters (`.when`, `.then`, `.and`) that
///    call [finalizeStep], then wrap the next scenario state in the
///    feature-specific builder.
///
/// ## Example (Given phase)
///
/// ```dart
/// class ProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
///   ProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
///       : super(scenario, StepPhase.given);
///
///   double _unitPrice = 0;
///
///   ProductGivenBuilder withUnitPrice(double price) {
///     _unitPrice = price;
///     return this;
///   }
///
///   @override
///   void applyToContext(TestContext ctx) {
///     ctx.set('product_unit_price', _unitPrice);
///   }
///
///   // Transition getter — defined by the subclass, NOT the framework,
///   // because it returns a feature-specific WhenBuilder.
///   OrderWhenBuilder get when {
///     final scenario = finalizeStep();
///     final next = scenario.addStep<NeedsThen>(
///       StepRecord(phase: StepPhase.when, action: (_) {}),
///     );
///     return OrderWhenBuilder(next);
///   }
/// }
/// ```
abstract class DomainObjectBuilder<TParent extends ScenarioState> {
  /// Create a domain object builder.
  ///
  /// [scenario] is the current scenario builder in state [TParent].
  /// [phase] is the step phase (given, when) this builder belongs to.
  DomainObjectBuilder(this._scenario, this._phase);

  final ScenarioBuilder<TParent> _scenario;
  final StepPhase _phase;

  /// Apply this builder's configured values to the test context.
  ///
  /// Subclasses override this to store domain objects or invoke use cases.
  void applyToContext(TestContext ctx);

  /// Finalize this builder: register the configured action as a step
  /// and return the updated scenario builder (same state [TParent]).
  ///
  /// Call this from transition getters (`.when`, `.then`, `.and`)
  /// before transitioning to the next state.
  ScenarioBuilder<TParent> finalizeStep() {
    return _scenario.appendStep(
      StepRecord(
        phase: _phase,
        action: (ctx) => applyToContext(ctx),
      ),
    );
  }
}
