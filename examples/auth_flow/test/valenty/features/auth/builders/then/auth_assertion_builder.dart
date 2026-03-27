import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'package:auth_flow_example/models/auth_result.dart';

import '../../fakes/fake_token_storage.dart';
import 'auth_then_builder.dart';

/// Fluent assertion builder for Authentication properties.
///
/// Available assertions:
/// - `.isAuthenticated(bool)` — assert auth status
/// - `.hasAccessToken(String)` — assert the access token value
/// - `.hasStoredToken(String)` — assert the token was stored in secure storage
/// - `.hasErrorMessage(String)` — assert the error message
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class AuthAssertionBuilder extends AssertionBuilder {
  AuthAssertionBuilder(super.scenario);

  /// Assert the authentication status.
  AuthAssertionBuilder isAuthenticated(bool expected) {
    addAssertionStep((ctx) {
      final result = ctx.get<AuthResult>('authResult');
      expect(
        result.success,
        equals(expected),
        reason: 'Expected isAuthenticated to be $expected',
      );
    });
    return this;
  }

  /// Assert the access token value in the auth result.
  AuthAssertionBuilder hasAccessToken(String expected) {
    addAssertionStep((ctx) {
      final result = ctx.get<AuthResult>('authResult');
      expect(
        result.token?.accessToken,
        equals(expected),
        reason: 'Expected access token to be $expected',
      );
    });
    return this;
  }

  /// Assert the token was stored in secure storage.
  AuthAssertionBuilder hasStoredToken(String expected) {
    addAssertionStep((ctx) {
      final storage = ctx.get<FakeTokenStorage>('fakeTokenStorage');
      expect(
        storage.storedToken?.accessToken,
        equals(expected),
        reason: 'Expected stored token to be $expected',
      );
    });
    return this;
  }

  /// Assert the error message.
  AuthAssertionBuilder hasErrorMessage(String expected) {
    addAssertionStep((ctx) {
      final result = ctx.get<AuthResult>('authResult');
      expect(
        result.errorMessage,
        equals(expected),
        reason: 'Expected error message to be "$expected"',
      );
    });
    return this;
  }

  /// Add more assertions.
  AuthAndThenBuilder get and => AuthAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
