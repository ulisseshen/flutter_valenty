import 'package:clean_arch_weather_example/features/weather/domain/entities/forecast.dart';
import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'weather_then_builder.dart';

/// Fluent assertion builder for Forecast entity properties.
///
/// Available assertions:
/// - `.hasCity(String)` — assert the forecast city
/// - `.hasDayCount(int)` — assert the number of forecast days
/// - `.dayAt(int)` — start asserting on a specific day
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class ForecastAssertionBuilder extends AssertionBuilder {
  ForecastAssertionBuilder(super.scenario);

  /// Assert the forecast is for the expected city.
  ForecastAssertionBuilder hasCity(String expected) {
    addAssertionStep((ctx) {
      final forecast = ctx.get<Forecast>('forecast');
      expect(
        forecast.city,
        equals(expected),
        reason: 'Expected forecast city to be "$expected"',
      );
    });
    return this;
  }

  /// Assert the forecast has the expected number of days.
  ForecastAssertionBuilder hasDayCount(int expected) {
    addAssertionStep((ctx) {
      final forecast = ctx.get<Forecast>('forecast');
      expect(
        forecast.days.length,
        equals(expected),
        reason: 'Expected $expected forecast days',
      );
    });
    return this;
  }

  /// Add more assertions.
  WeatherAndThenBuilder get and => WeatherAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
