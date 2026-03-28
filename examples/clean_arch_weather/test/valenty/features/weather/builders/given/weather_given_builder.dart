import 'package:valenty_test/valenty_test.dart';

import 'api_weather_given_builder.dart';
import 'cached_weather_given_builder.dart';
import 'favorite_cities_given_builder.dart';

/// GivenBuilder for the Weather feature.
///
/// Provides domain objects available in the Given phase:
/// - `.apiWeather()` — configure what the remote API returns
/// - `.cachedWeather()` — pre-populate the local cache
/// - `.favoriteCities()` — set up favorite cities
class WeatherGivenBuilder extends GivenBuilder {
  WeatherGivenBuilder(super.scenario);

  /// Configure API weather response.
  ApiWeatherGivenBuilder apiWeather() => ApiWeatherGivenBuilder(scenario);

  /// Pre-populate cached weather data.
  CachedWeatherGivenBuilder cachedWeather() =>
      CachedWeatherGivenBuilder(scenario);

  /// Set up favorite cities.
  FavoriteCitiesGivenBuilder favoriteCities() =>
      FavoriteCitiesGivenBuilder(scenario);
}
