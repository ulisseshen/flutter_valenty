import 'package:valenty_dsl/valenty_dsl.dart';

import '../../fakes/fake_auth_api.dart';
import '../when/auth_when_builder.dart';
import 'auth_given_builder.dart';

/// Builder for configuring the fake API response in the Given phase.
///
/// This is where the test's precondition meets the fake: we configure
/// what the FakeAuthApi will return when called during the When phase.
///
/// Available methods:
/// - `.withSuccessResponse(...)` — API will return a valid token
/// - `.withErrorResponse(...)` — API will throw an error
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class ApiResponseGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiResponseGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String? _accessToken;
  String _refreshToken = 'default-refresh';
  int? _errorStatusCode;
  String? _errorMessage;

  /// Configure the fake API to return a successful auth token.
  ApiResponseGivenBuilder withSuccessResponse({
    required String accessToken,
    String refreshToken = 'default-refresh',
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _errorStatusCode = null;
    _errorMessage = null;
    return this;
  }

  /// Configure the fake API to return an error.
  ApiResponseGivenBuilder withErrorResponse({
    required int statusCode,
    required String message,
  }) {
    _errorStatusCode = statusCode;
    _errorMessage = message;
    _accessToken = null;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final fakeApi = FakeAuthApi();

    if (_accessToken != null) {
      fakeApi.setSuccessResponse(
        accessToken: _accessToken!,
        refreshToken: _refreshToken,
      );
    } else if (_errorStatusCode != null) {
      fakeApi.setErrorResponse(
        statusCode: _errorStatusCode!,
        message: _errorMessage!,
      );
    }

    ctx.set('fakeAuthApi', fakeApi);
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
