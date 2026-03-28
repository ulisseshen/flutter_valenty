import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'package:auth_flow_example/models/auth_result.dart';

import 'auth_assertion_builder.dart';

/// ThenBuilder for the Authentication feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the login succeeded
/// - `.shouldFail()` — assert the login failed
/// - `.auth()` — fluent assertion builder for auth properties
class AuthThenBuilder extends ThenBuilder {
  AuthThenBuilder(super.scenario);

  /// Assert the login succeeded.
  AuthThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final result = ctx.get<AuthResult>('authResult');
      expect(result.success, isTrue, reason: 'Expected login to succeed');
    });
    return AuthThenTerminal(next);
  }

  /// Assert the login failed.
  AuthThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final result = ctx.get<AuthResult>('authResult');
      expect(result.success, isFalse, reason: 'Expected login to fail');
    });
    return AuthThenTerminal(next);
  }

  /// Start a fluent assertion chain for auth properties.
  AuthAssertionBuilder auth() => AuthAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class AuthThenTerminal {
  AuthThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  AuthAndThenBuilder get and => AuthAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Authentication feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class AuthAndThenBuilder extends AndThenBuilder {
  AuthAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for auth properties.
  AuthAssertionBuilder auth() => AuthAssertionBuilder(scenario);
}
