import 'package:valenty_dsl/valenty_dsl.dart';

import 'builders/given/weather_given_builder.dart';

/// Entry point for Weather feature acceptance tests.
///
/// Usage:
/// ```dart
/// WeatherScenario('should return weather for a valid city')
///     .given
///     .apiWeather()
///         .withCity('London')
///         .withTemperature(15.0)
///         .withDescription('Cloudy')
///         .withHumidity(72)
///     .when
///     .searchWeather()
///         .forCity('London')
///     .then
///     .shouldSucceed()
///     .and
///     .weather()
///         .hasCity('London')
///         .hasTemperature(15.0)
///     .run();
/// ```
class WeatherScenario extends FeatureScenario<WeatherGivenBuilder> {
  WeatherScenario(super.description);

  @override
  WeatherGivenBuilder createGivenBuilder(
    ScenarioBuilder<NeedsWhen> scenario,
  ) {
    return WeatherGivenBuilder(scenario);
  }
}
