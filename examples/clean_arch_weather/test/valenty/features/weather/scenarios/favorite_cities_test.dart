// =============================================================================
// FAVORITE CITIES ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Weather Forecast App — Favorite Cities
//
// These scenarios test that favorite cities are correctly stored and
// that weather can be fetched for favorited cities. The favorite cities
// list is managed through the local datasource.
//
// QA Scenarios:
//
//   1. "Given London and Paris are favorite cities and the API has weather,
//       when the user searches for London,
//       then they should see London's weather"
//
//   2. "Given favorite cities and API is down but cache exists,
//       when the user searches for a favorite city,
//       then they should see cached weather"
//
// =============================================================================

import 'package:test/test.dart';

import '../weather_scenario.dart';

void main() {
  group('Favorite Cities', () {
    // --- Scenario 1: Weather for a favorite city -------------------------
    WeatherScenario('should return weather for favorite cities')
        .given
        .favoriteCities()
            .withCity('London')
            .withCity('Paris')
        .and
        .apiWeather()
            .withCity('London')
            .withTemperature(15.0)
        .when
        .searchWeather()
            .forCity('London')
        .then
        .weather()
            .hasCity('London')
            .hasTemperature(15.0)
        .run();

    // --- Scenario 2: Favorite city with cache fallback -------------------
    WeatherScenario('should return cached weather for favorite city when API fails')
        .given
        .favoriteCities()
            .withCity('Berlin')
        .and
        .apiWeather()
            .withServerError(503)
        .and
        .cachedWeather()
            .withCity('Berlin')
            .withTemperature(10.0)
            .withDescription('Overcast')
        .when
        .searchWeather()
            .forCity('Berlin')
        .then
        .shouldSucceed()
        .and
        .weather()
            .hasCity('Berlin')
            .hasTemperature(10.0)
            .hasDescription('Overcast')
        .run();

    // --- Scenario 3: Multiple favorites with specific search -------------
    WeatherScenario('should return correct weather when multiple favorites exist')
        .given
        .favoriteCities()
            .withCity('Tokyo')
            .withCity('New York')
            .withCity('Sydney')
        .and
        .apiWeather()
            .withCity('New York')
            .withTemperature(-2.0)
            .withDescription('Snow')
            .withHumidity(90)
        .when
        .searchWeather()
            .forCity('New York')
        .then
        .shouldSucceed()
        .and
        .weather()
            .hasCity('New York')
            .hasTemperature(-2.0)
            .hasDescription('Snow')
            .hasHumidity(90)
        .run();
  });
}
