import 'package:valenty_dsl/valenty_dsl.dart';

import 'search_weather_when_builder.dart';
import 'get_forecast_when_builder.dart';

/// WhenBuilder for the Weather feature.
///
/// Provides use cases available in the When phase:
/// - `.searchWeather()` — search current weather for a city
/// - `.getForecast()` — get multi-day forecast for a city
class WeatherWhenBuilder extends WhenBuilder {
  WeatherWhenBuilder(super.scenario);

  /// Trigger the "get current weather" use case.
  SearchWeatherWhenBuilder searchWeather() =>
      SearchWeatherWhenBuilder(scenario);

  /// Trigger the "get forecast" use case.
  GetForecastWhenBuilder getForecast() => GetForecastWhenBuilder(scenario);
}
