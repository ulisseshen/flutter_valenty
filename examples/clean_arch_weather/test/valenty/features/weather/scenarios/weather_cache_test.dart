// =============================================================================
// WEATHER CACHE FALLBACK ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Weather Forecast App — Cache Fallback Strategy
//
// These scenarios test the repository's fallback behavior:
// when the remote API fails, the repository falls back to cached data.
// If no cached data exists, the operation fails gracefully.
//
// This demonstrates the Clean Architecture testing strategy:
// fake at the datasource boundary, keep the repository REAL.
//
// QA Scenarios:
//
//   1. "Given the API is down (503) but London weather is cached,
//       when the user searches for London,
//       then they should see the cached weather"
//
//   2. "Given the API is down (503) and no cache exists,
//       when the user searches for Tokyo,
//       then the operation should fail"
//
//   3. "Given a successful API call,
//       when the user searches and then the API goes down,
//       the cached data from the first call should be available"
//
// =============================================================================

import 'package:test/test.dart';

import '../weather_scenario.dart';

void main() {
  group('Weather Cache Fallback', () {
    // --- Scenario 1: Fallback to cache on API failure --------------------
    WeatherScenario('should return cached weather when API fails')
        .given
        .apiWeather()
            .withServerError(503)
        .and
        .cachedWeather()
            .withCity('London')
            .withTemperature(14.0)
            .withDescription('Partly cloudy')
        .when
        .searchWeather()
            .forCity('London')
        .then
        .shouldSucceed()
        .and
        .weather()
            .hasCity('London')
            .hasTemperature(14.0)
        .run();

    // --- Scenario 2: Fail when API down and no cache ---------------------
    WeatherScenario('should fail when API fails and no cache exists')
        .given
        .apiWeather()
            .withServerError(503)
        .when
        .searchWeather()
            .forCity('Tokyo')
        .then
        .shouldFail()
        .run();

    // --- Scenario 3: Cache with full details ----------------------------
    WeatherScenario('should return cached weather with all details')
        .given
        .apiWeather()
            .withServerError(500)
        .and
        .cachedWeather()
            .withCity('Paris')
            .withTemperature(22.0)
            .withDescription('Warm and sunny')
            .withHumidity(38)
            .withWindSpeed(2.1)
        .when
        .searchWeather()
            .forCity('Paris')
        .then
        .shouldSucceed()
        .and
        .weather()
            .hasCity('Paris')
            .hasTemperature(22.0)
            .hasDescription('Warm and sunny')
            .hasHumidity(38)
            .hasWindSpeed(2.1)
        .run();
  });
}
