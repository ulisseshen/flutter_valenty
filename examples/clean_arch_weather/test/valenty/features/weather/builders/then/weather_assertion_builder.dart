import 'package:clean_arch_weather_example/features/weather/domain/entities/weather.dart';
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'weather_then_builder.dart';

/// Fluent assertion builder for Weather entity properties.
///
/// Available assertions:
/// - `.hasCity(String)` — assert the city name
/// - `.hasTemperature(double)` — assert the temperature
/// - `.hasDescription(String)` — assert the description
/// - `.hasHumidity(int)` — assert the humidity
/// - `.hasWindSpeed(double)` — assert the wind speed
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class WeatherAssertionBuilder extends AssertionBuilder {
  WeatherAssertionBuilder(super.scenario);

  /// Assert the weather has the expected city name.
  WeatherAssertionBuilder hasCity(String expected) {
    addAssertionStep((ctx) {
      final weather = ctx.get<Weather>('weather');
      expect(
        weather.city,
        equals(expected),
        reason: 'Expected city to be "$expected"',
      );
    });
    return this;
  }

  /// Assert the weather has the expected temperature.
  WeatherAssertionBuilder hasTemperature(double expected) {
    addAssertionStep((ctx) {
      final weather = ctx.get<Weather>('weather');
      expect(
        weather.temperature,
        equals(expected),
        reason: 'Expected temperature to be $expected',
      );
    });
    return this;
  }

  /// Assert the weather has the expected description.
  WeatherAssertionBuilder hasDescription(String expected) {
    addAssertionStep((ctx) {
      final weather = ctx.get<Weather>('weather');
      expect(
        weather.description,
        equals(expected),
        reason: 'Expected description to be "$expected"',
      );
    });
    return this;
  }

  /// Assert the weather has the expected humidity.
  WeatherAssertionBuilder hasHumidity(int expected) {
    addAssertionStep((ctx) {
      final weather = ctx.get<Weather>('weather');
      expect(
        weather.humidity,
        equals(expected),
        reason: 'Expected humidity to be $expected',
      );
    });
    return this;
  }

  /// Assert the weather has the expected wind speed.
  WeatherAssertionBuilder hasWindSpeed(double expected) {
    addAssertionStep((ctx) {
      final weather = ctx.get<Weather>('weather');
      expect(
        weather.windSpeed,
        equals(expected),
        reason: 'Expected wind speed to be $expected',
      );
    });
    return this;
  }

  /// Add more assertions.
  WeatherAndThenBuilder get and => WeatherAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
