import 'package:valenty_test/valenty_test.dart';

import '../when/ordering_when_builder.dart';
import 'ordering_given_builder.dart';

/// Builder for configuring the fake Order API behavior in the Given phase.
///
/// Available methods:
/// - `.withOrderApiSucceeding()` — API will return a confirmed Order
/// - `.withOrderApiFailing({statusCode, message})` — API will throw
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class ApiConfigGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiConfigGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  bool _shouldFail = false;
  int _failStatusCode = 500;
  String _failMessage = 'Internal server error';

  ApiConfigGivenBuilder withOrderApiSucceeding() {
    _shouldFail = false;
    return this;
  }

  ApiConfigGivenBuilder withOrderApiFailing({
    int statusCode = 500,
    String message = 'Internal server error',
  }) {
    _shouldFail = true;
    _failStatusCode = statusCode;
    _failMessage = message;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('apiShouldFail', _shouldFail);
    ctx.set('apiFailStatusCode', _failStatusCode);
    ctx.set('apiFailMessage', _failMessage);
  }

  /// Transition to When phase.
  OrderingWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderingWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  OrderingGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderingGivenBuilder(finalized);
  }
}
