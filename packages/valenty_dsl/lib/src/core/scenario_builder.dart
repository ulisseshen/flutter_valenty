import 'phantom_types.dart';
import 'step_record.dart';
import 'test_context.dart';

/// The core scenario builder with compile-time state tracking.
///
/// The type parameter [S] is a phantom type that determines which
/// transition methods (given, when, then, and, run) are available.
///
/// Users never instantiate this directly. Instead, they create a
/// feature-specific scenario class that uses this builder internally.
class ScenarioBuilder<S extends ScenarioState> {
  ScenarioBuilder._({
    required String description,
    required List<StepRecord> steps,
    required TestContext context,
  })  : _description = description,
        _steps = List.unmodifiable(steps),
        _context = context;

  final String _description;
  final List<StepRecord> _steps;
  final TestContext _context;

  /// The scenario description (used for test registration).
  String get description => _description;

  /// All recorded steps so far (immutable list).
  List<StepRecord> get steps => _steps;

  /// The shared test context passed to all steps.
  TestContext get context => _context;

  /// Create a new scenario builder in the [NeedsGiven] state.
  static ScenarioBuilder<NeedsGiven> create(String description) {
    return ScenarioBuilder<NeedsGiven>._(
      description: description,
      steps: const [],
      context: TestContext(),
    );
  }

  /// Add a step and transition to a new state [T].
  ///
  /// This changes the phantom type, enabling different methods
  /// on the returned builder.
  ScenarioBuilder<T> addStep<T extends ScenarioState>(StepRecord step) {
    return ScenarioBuilder<T>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }

  /// Add a step without changing state.
  ///
  /// Used when appending additional steps within the same phase
  /// (e.g., multiple assertions in the Then phase).
  ScenarioBuilder<S> appendStep(StepRecord step) {
    return ScenarioBuilder<S>._(
      description: _description,
      steps: [..._steps, step],
      context: _context,
    );
  }
}
