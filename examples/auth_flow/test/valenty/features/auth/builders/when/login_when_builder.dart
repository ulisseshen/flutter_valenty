import 'package:valenty_dsl/valenty_dsl.dart';

import 'package:auth_flow_example/models/auth_result.dart';
import 'package:auth_flow_example/models/user.dart';

import '../../fakes/fake_auth_api.dart';
import '../../fakes/fake_token_storage.dart';
import '../../fakes/fake_user_prefs.dart';
import '../then/auth_then_builder.dart';

/// Builder for the "login" use case.
///
/// Executes the authentication flow using the fakes configured
/// in the Given phase. This is the core of the component test:
/// real use case logic, fake infrastructure.
class LoginWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  LoginWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  @override
  void applyToContext(TestContext ctx) {
    // Retrieve fakes and configuration from context
    final fakeApi = ctx.get<FakeAuthApi>('fakeAuthApi');
    final email = ctx.get<String>('loginEmail');
    final password = ctx.get<String>('loginPassword');

    // Create fresh fakes for storage (these start empty)
    final fakeTokenStorage = FakeTokenStorage();
    final fakeUserPrefs = FakeUserPrefs();

    // Store fakes in context so Then phase can inspect them
    ctx.set('fakeTokenStorage', fakeTokenStorage);
    ctx.set('fakeUserPrefs', fakeUserPrefs);

    // Execute the login use case synchronously.
    // Since all fakes are in-memory with no real I/O, we use
    // synchronous helpers to avoid async microtask gaps.
    try {
      // Step 1: Call auth API
      final token = fakeApi.loginSync(email, password);

      // Step 2: Store token in secure storage
      fakeTokenStorage.saveTokenSync(token);

      // Step 3: Save user preferences
      final user = User(
        id: 'user-1',
        email: email,
        name: email.split('@').first,
      );
      fakeUserPrefs.saveUserPrefsSync(user);

      // Step 4: Store auth result
      ctx.set(
        'authResult',
        AuthResult(
          success: true,
          user: user,
          token: token,
        ),
      );
    } on AuthApiException catch (e) {
      ctx.set(
        'authResult',
        AuthResult(
          success: false,
          errorMessage: e.message,
        ),
      );
    }
  }

  /// Transition to Then phase.
  AuthThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return AuthThenBuilder(next);
  }
}
