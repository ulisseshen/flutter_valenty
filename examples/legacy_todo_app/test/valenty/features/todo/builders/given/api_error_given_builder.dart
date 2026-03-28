import 'package:valenty_test/valenty_test.dart';

import '../when/todo_when_builder.dart';
import 'todo_given_builder.dart';

/// Builder for configuring API errors in the Given phase.
///
/// Available methods:
/// - `.withServerError(int statusCode)` — set the error status code
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class ApiErrorGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiErrorGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  int _statusCode = 500;

  /// Configure the API to fail with a specific HTTP status code.
  ApiErrorGivenBuilder withServerError(int statusCode) {
    _statusCode = statusCode;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('apiHasError', true);
    ctx.set('apiErrorCode', _statusCode);
  }

  /// Transition to When phase.
  TodoWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return TodoWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  TodoGivenBuilder get and {
    final finalized = finalizeStep();
    return TodoGivenBuilder(finalized);
  }
}
