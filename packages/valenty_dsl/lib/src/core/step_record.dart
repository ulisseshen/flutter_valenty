import 'test_context.dart';

/// The phase of a scenario step.
enum StepPhase {
  /// Precondition setup.
  given,

  /// Action / event being tested.
  when,

  /// Assertion / expected outcome.
  then,

  /// Additional precondition or assertion (continuation of previous phase).
  and,
}

/// A recorded step action in a scenario.
///
/// Unlike the old string-based Step class, StepRecord stores structured
/// actions without requiring user-supplied description strings.
/// The action itself IS the step — typed builder methods are the actions.
final class StepRecord {
  /// Create a step record with the given [phase], [action], and optional
  /// [description].
  const StepRecord({
    required this.phase,
    required this.action,
    this.description,
  });

  /// Which phase this step belongs to.
  final StepPhase phase;

  /// The action to execute. Receives [TestContext], may return Future.
  final dynamic Function(TestContext ctx) action;

  /// Optional human-readable description for reporting/logging.
  /// This is auto-generated from builder method names, NOT user-supplied.
  final String? description;
}
