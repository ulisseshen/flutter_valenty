import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/step_record.dart';
import '../core/test_environment.dart';

/// Abstract base for feature-specific scenario entry points.
///
/// Extend this to create a typed scenario for each feature. It provides
/// the `.given` getter that returns your custom GivenBuilder.
///
/// ## Basic usage (no infrastructure setup)
///
/// ```dart
/// class OrderScenario extends FeatureScenario<OrderGivenBuilder> {
///   OrderScenario(super.description, [super.environment]);
///
///   @override
///   OrderGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> s) =>
///       OrderGivenBuilder(s);
/// }
/// ```
///
/// ```dart
/// OrderScenario('should calculate base price')
///   .given.product().withUnitPrice(20.00)
///   .when.placeOrder().withQuantity(5)
///   .then.shouldSucceed()
///   .run();
/// ```
///
/// ## With infrastructure setup (component tests)
///
/// ```dart
/// final env = TestEnvironment()
///     .setup(() => OrderService.httpFactory = () => fakeHttp)
///     .teardown(() => OrderService.httpFactory = () => RealHttp());
///
/// OrderScenario('should calculate total', env)
///     .given.product().withUnitPrice(20.00)
///     .when.placeOrder().withQuantity(5)
///     .then.order().hasTotalPrice(100.00)
///     .run();
/// ```
abstract class FeatureScenario<TGiven> {
  /// Create a new feature scenario with the given description.
  ///
  /// Optionally pass a [TestEnvironment] for infrastructure setup/teardown.
  /// The environment's setup actions run before steps, and teardown actions
  /// run after steps (even on failure).
  FeatureScenario(String description, [TestEnvironment? environment])
      : _builder = ScenarioBuilder.create(description),
        _environment = environment {
    // Store environment in context so ScenarioRunner can access it
    if (environment != null) {
      _builder.context.set(
        TestEnvironment.contextKey,
        environment,
      );
    }
  }

  final ScenarioBuilder<NeedsGiven> _builder;
  final TestEnvironment? _environment;

  /// The test environment, if one was provided.
  TestEnvironment? get environment => _environment;

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
