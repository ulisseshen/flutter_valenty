import 'package:test/test.dart' as test_pkg;

import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Executes a completed scenario as a `package:test` test case.
class ScenarioRunner {
  const ScenarioRunner._();

  /// Run a scenario as a test.
  ///
  /// Each recorded step's action is executed in order, with async
  /// actions properly awaited.
  static void run(ScenarioBuilder<ReadyToRun> scenario) {
    test_pkg.test(scenario.description, () async {
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
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
      for (final step in scenario.steps) {
        final result = step.action(scenario.context);
        if (result is Future) {
          await result;
        }
      }
    });
  }

  /// Run a scenario directly (without registering a test).
  ///
  /// Useful for testing the scenario builder itself.
  static Future<void> execute(ScenarioBuilder<ReadyToRun> scenario) async {
    for (final step in scenario.steps) {
      final result = step.action(scenario.context);
      if (result is Future) {
        await result;
      }
    }
  }
}
