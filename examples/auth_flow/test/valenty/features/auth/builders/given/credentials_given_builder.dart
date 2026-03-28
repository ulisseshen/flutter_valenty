import 'package:valenty_test/valenty_test.dart';

import '../when/auth_when_builder.dart';
import 'auth_given_builder.dart';

/// Builder for setting up login credentials in the Given phase.
///
/// Available methods:
/// - `.withEmail(String)` — set login email
/// - `.withPassword(String)` — set login password
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class CredentialsGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CredentialsGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _email = 'test@example.com';
  String _password = 'password';

  CredentialsGivenBuilder withEmail(String email) {
    _email = email;
    return this;
  }

  CredentialsGivenBuilder withPassword(String password) {
    _password = password;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('loginEmail', _email);
    ctx.set('loginPassword', _password);
  }

  /// Transition to When phase.
  AuthWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return AuthWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  AuthGivenBuilder get and {
    final finalized = finalizeStep();
    return AuthGivenBuilder(finalized);
  }
}
