import '../entities/forecast.dart';
import '../entities/weather.dart';

/// Abstract repository for weather operations.
///
/// Defined in the DOMAIN layer — no knowledge of APIs, caches, or data models.
/// The DATA layer provides the concrete implementation.
abstract class WeatherRepository {
  /// Get current weather for a city.
  Future<Weather> getCurrentWeather(String city);

  /// Get a multi-day forecast for a city.
  Future<Forecast> getForecast(String city, {int days = 5});

  /// Get the list of favorite cities.
  Future<List<String>> getFavoriteCities();

  /// Add a city to favorites.
  Future<void> addFavoriteCity(String city);

  /// Remove a city from favorites.
  Future<void> removeFavoriteCity(String city);
}
