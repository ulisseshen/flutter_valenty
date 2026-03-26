import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';

/// Abstract base for feature-specific scenario entry points.
///
/// Extend this to create a typed scenario for each feature. It provides
/// the `.given` getter that returns your custom GivenBuilder.
///
/// ## Example
///
/// ```dart
/// class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
///   OrderScenario(super.description);
///
///   @override
///   OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> s) =>
///       OrderGivenBuilder(s);
/// }
/// ```
///
/// Usage:
/// ```dart
/// OrderScenario('should calculate base price')
///   .given.product().withUnitPrice(20.00)
///   .when.placeOrder().withQuantity(5)
///   .then.shouldSucceed()
///   .run();
/// ```
abstract class FeatureScenario<TGiven> {
  /// Create a new feature scenario with the given description.
  FeatureScenario(String description)
      : _builder = ScenarioBuilder.create(description);

  final ScenarioBuilder<NeedsGiven> _builder;

  /// Factory method: create the feature-specific Given builder.
  TGiven createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario);

  /// Transition to the Given phase.
  ///
  /// Returns the feature-specific GivenBuilder with domain methods
  /// available for IDE autocompletion.
  TGiven get given {
    final nextState = _builder.addStep<NeedsWhen>(
      StepRecord(phase: StepPhase.given, action: (_) {}),
    );
    return createGivenBuilder(nextState);
  }
}
