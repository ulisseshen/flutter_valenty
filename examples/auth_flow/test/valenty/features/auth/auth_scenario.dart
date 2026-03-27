import 'package:valenty_dsl/valenty_dsl.dart';

import 'builders/given/auth_given_builder.dart';

/// Entry point for Authentication feature acceptance tests.
///
/// Usage:
/// ```dart
/// AuthScenario('should authenticate user with valid credentials')
///     .given
///     .apiResponse()
///         .withSuccessResponse(accessToken: 'abc123')
///     .and
///     .credentials()
///         .withEmail('user@example.com')
///         .withPassword('password123')
///     .when
///     .login()
///     .then
///     .shouldSucceed();
/// ```
class AuthScenario extends FeatureScenario<AuthGivenBuilder> {
  AuthScenario(super.description);

  @override
  AuthGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return AuthGivenBuilder(scenario);
  }
}
