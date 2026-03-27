import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/expense_when_builder.dart';
import 'expense_given_builder.dart';

/// Builder for configuring the authenticated user in the Given phase.
///
/// Available methods:
/// - `.asUser(userId, email)` — set the current authenticated user
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class AuthGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  AuthGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _userId = 'test-user';
  String _email = 'test@example.com';

  /// Set the current authenticated user.
  AuthGivenBuilder asUser(String userId, String email) {
    _userId = userId;
    _email = email;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('authUserId', _userId);
    ctx.set('authEmail', _email);
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
