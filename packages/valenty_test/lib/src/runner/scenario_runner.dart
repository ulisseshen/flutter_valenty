import 'package:test/test.dart' as test_pkg;

import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';
import '../core/test_environment.dart';

/// Executes a completed scenario as a `package:test` test case.
///
/// If a [TestEnvironment] was registered (via [FeatureScenario]),
/// its setup actions run before steps and teardown actions run after
/// steps (even on failure).
class ScenarioRunner {
  const ScenarioRunner._();

  /// Extract [TestEnvironment] from the scenario context, if present.
  static TestEnvironment? _getEnvironment(
    ScenarioBuilder<ReadyToRun> scenario,
  ) {
    if (scenario.context.has(TestEnvironment.contextKey)) {
      return scenario.context.get<TestEnvironment>(
        TestEnvironment.contextKey,
      );
    }
    return null;
  }

  /// Execute all steps in order, awaiting async actions.
  static Future<void> _executeSteps(
    ScenarioBuilder<ReadyToRun> scenario,
  ) async {
    for (final step in scenario.steps) {
      final result = step.action(scenario.context);
      if (result is Future) {
        await result;
      }
    }
  }

  /// Run a scenario as a test.
  ///
  /// If a [TestEnvironment] is present, setup runs before steps
  /// and teardown runs after steps (guaranteed via try/finally).
  static void run(ScenarioBuilder<ReadyToRun> scenario) {
    test_pkg.test(scenario.description, () async {
      final env = _getEnvironment(scenario);
      if (env != null) await env.apply();
      try {
        await _executeSteps(scenario);
      } finally {
        if (env != null) await env.restore();
      }
    });
  }

  /// Run a scenario as a test with a channel label prefix.
  ///
  /// The test name becomes `[channelName] description`.
  static void runWithChannel(
    ScenarioBuilder<ReadyToRun> scenario, {
    required String channelName,
  }) {
    test_pkg.test('[$channelName] ${scenario.description}', () async {
      final env = _getEnvironment(scenario);
      if (env != null) await env.apply();
      try {
        await _executeSteps(scenario);
      } finally {
        if (env != null) await env.restore();
      }
    });
  }

  /// Run a scenario directly (without registering a test).
  ///
  /// Useful for testing the scenario builder itself.
  static Future<void> execute(ScenarioBuilder<ReadyToRun> scenario) async {
    final env = _getEnvironment(scenario);
    if (env != null) await env.apply();
    try {
      await _executeSteps(scenario);
    } finally {
      if (env != null) await env.restore();
    }
  }
}
