// =============================================================================
// AUTHENTICATION FLOW ACCEPTANCE TESTS
// =============================================================================
//
// QA Scenarios (plain English from QA team):
//
//   1. "Given a valid API response with token 'abc123' and valid credentials,
//       when the user logs in,
//       then the login should succeed
//       and the user should be authenticated with token 'abc123'"
//
//   2. "Given an API error 401 'Invalid credentials' and any credentials,
//       when the user logs in,
//       then the login should fail
//       and the error message should be 'Invalid credentials'"
//
//   3. "Given a valid API response with token 'token789' and valid credentials,
//       when the user logs in,
//       then the login should succeed
//       and the token 'token789' should be stored in secure storage"
//
// AI translated these scenarios into compile-time safe typed DSL below.
// No strings. No runtime failures. IDE guides every step.
//
// NOTE: The ports (AuthApiPort, TokenStoragePort, UserPrefsPort) are
// abstract classes — the fakes implement them without any real packages
// (no Dio, no FlutterSecureStorage, no SharedPreferences).
// =============================================================================

import 'package:test/test.dart';

import '../auth_scenario.dart';

void main() {
  group('Authentication', () {
    // ─── QA Scenario 1 ─────────────────────────────────────────────────
    // "Given a valid API response and valid credentials,
    //  when the user logs in,
    //  then the login should succeed and the user is authenticated"
    //
    AuthScenario('should authenticate user with valid credentials')
        .given
        .apiResponse()
        .withSuccessResponse(
          accessToken: 'abc123',
          refreshToken: 'refresh456',
        )
        .and
        .credentials()
        .withEmail('user@example.com')
        .withPassword('password123')
        .when
        .login()
        .then
        .shouldSucceed()
        .and
        .auth()
        .isAuthenticated(true)
        .hasAccessToken('abc123')
        .run();

    // ─── QA Scenario 2 ─────────────────────────────────────────────────
    // "Given an API error 401 and any credentials,
    //  when the user logs in,
    //  then the login should fail with 'Invalid credentials'"
    //
    AuthScenario('should reject invalid credentials')
        .given
        .apiResponse()
        .withErrorResponse(statusCode: 401, message: 'Invalid credentials')
        .and
        .credentials()
        .withEmail('user@example.com')
        .withPassword('wrong')
        .when
        .login()
        .then
        .shouldFail()
        .and
        .auth()
        .hasErrorMessage('Invalid credentials')
        .run();

    // ─── QA Scenario 3 ─────────────────────────────────────────────────
    // "Given a valid API response with token 'token789',
    //  when the user logs in,
    //  then the token should be stored in secure storage"
    //
    AuthScenario('should store token in secure storage after login')
        .given
        .apiResponse()
        .withSuccessResponse(accessToken: 'token789')
        .and
        .credentials()
        .withEmail('user@example.com')
        .withPassword('password123')
        .when
        .login()
        .then
        .shouldSucceed()
        .and
        .auth()
        .hasStoredToken('token789')
        .run();
  });
}
