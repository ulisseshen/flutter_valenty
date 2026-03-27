import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/expense_when_builder.dart';
import 'expense_given_builder.dart';

/// Builder for overriding the clock in the Given phase.
///
/// Available methods:
/// - `.withFixedDate(DateTime)` — set a fixed date for the clock factory
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class ClockGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ClockGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  DateTime _fixedDate = DateTime(2025, 6, 15, 10, 30);

  /// Set a fixed date for the clock factory.
  ClockGivenBuilder withFixedDate(DateTime date) {
    _fixedDate = date;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('fixedClock', _fixedDate);
  }

  /// Transition to When phase.
  ExpenseWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return ExpenseWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  ExpenseGivenBuilder get and {
    final finalized = finalizeStep();
    return ExpenseGivenBuilder(finalized);
  }
}
