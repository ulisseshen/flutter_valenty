import 'package:valenty_test/valenty_test.dart';

import '../when/ordering_when_builder.dart';
import 'ordering_given_builder.dart';

/// Builder for setting the preferred currency in the Given phase.
///
/// Available methods:
/// - `.withCurrency(String)` — set preferred currency code
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class CurrencyGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CurrencyGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _currency = 'USD';

  CurrencyGivenBuilder withCurrency(String currency) {
    _currency = currency;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('preferredCurrency', _currency);
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
