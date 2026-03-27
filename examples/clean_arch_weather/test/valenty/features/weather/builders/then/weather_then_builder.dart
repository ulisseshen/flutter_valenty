import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'weather_assertion_builder.dart';
import 'forecast_assertion_builder.dart';

/// ThenBuilder for the Weather feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the operation succeeded
/// - `.shouldFail()` — assert the operation failed
/// - `.weather()` — fluent assertion builder for weather properties
/// - `.forecast()` — fluent assertion builder for forecast properties
class WeatherThenBuilder extends ThenBuilder {
  WeatherThenBuilder(super.scenario);

  /// Assert the operation succeeded.
  WeatherThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final failed = ctx.has('operationFailed')
          ? ctx.get<bool>('operationFailed')
          : false;
      expect(failed, isFalse, reason: 'Expected operation to succeed');
    });
    return WeatherThenTerminal(next);
  }

  /// Assert the operation failed.
  WeatherThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('operationFailed');
      expect(failed, isTrue, reason: 'Expected operation to fail');
    });
    return WeatherThenTerminal(next);
  }

  /// Start a fluent assertion chain for weather.
  WeatherAssertionBuilder weather() => WeatherAssertionBuilder(scenario);

  /// Start a fluent assertion chain for forecast.
  ForecastAssertionBuilder forecast() => ForecastAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class WeatherThenTerminal {
  WeatherThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  WeatherAndThenBuilder get and => WeatherAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Weather feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class WeatherAndThenBuilder extends AndThenBuilder {
  WeatherAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for weather.
  WeatherAssertionBuilder weather() => WeatherAssertionBuilder(scenario);

  /// Start a fluent assertion chain for forecast.
  ForecastAssertionBuilder forecast() => ForecastAssertionBuilder(scenario);
}
