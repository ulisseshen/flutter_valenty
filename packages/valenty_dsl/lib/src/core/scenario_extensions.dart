import 'phantom_types.dart';
import 'scenario_builder.dart';
import '../runner/scenario_runner.dart';

/// Extension on [ScenarioBuilder<ReadyToRun>] providing `.run()`.
extension ReadyToRunExtension on ScenarioBuilder<ReadyToRun> {
  /// Execute this scenario as a `package:test` test case.
  void run() {
    ScenarioRunner.run(this);
  }

  /// Execute this scenario as a test with a specific channel label.
  void runWithChannel(String channelName) {
    ScenarioRunner.runWithChannel(this, channelName: channelName);
  }
}
