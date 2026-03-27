// =============================================================================
// CURRENT WEATHER ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Weather Forecast App — Current Weather
//
// These scenarios test the GetCurrentWeather use case through the
// REAL WeatherRepositoryImpl with FAKE datasources.
//
// QA Scenarios:
//
//   1. "Given the API returns weather for London at 15C and Cloudy,
//       when the user searches for London,
//       then they should see London, 15C, Cloudy"
//
//   2. "Given the API returns weather with full details,
//       when the user searches for that city,
//       then all weather properties should match"
//
// =============================================================================

import 'package:test/test.dart';

import '../weather_scenario.dart';

void main() {
  group('Current Weather', () {
    // --- Scenario 1: Basic weather search --------------------------------
    WeatherScenario('should return weather for a valid city')
        .given
        .apiWeather()
            .withCity('London')
            .withTemperature(15.0)
            .withDescription('Cloudy')
            .withHumidity(72)
        .when
        .searchWeather()
            .forCity('London')
        .then
        .shouldSucceed()
        .and
        .weather()
            .hasCity('London')
            .hasTemperature(15.0)
            .hasDescription('Cloudy')
        .run();

    // --- Scenario 2: Full weather details --------------------------------
    WeatherScenario('should return all weather details')
        .given
        .apiWeather()
            .withCity('Tokyo')
            .withTemperature(28.5)
            .withDescription('Sunny')
            .withHumidity(45)
            .withWindSpeed(3.2)
        .when
        .searchWeather()
            .forCity('Tokyo')
        .then
        .weather()
            .hasCity('Tokyo')
            .hasTemperature(28.5)
            .hasDescription('Sunny')
            .hasHumidity(45)
            .hasWindSpeed(3.2)
        .run();
  });
}
