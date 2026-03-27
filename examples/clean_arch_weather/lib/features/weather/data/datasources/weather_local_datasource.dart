import '../models/weather_model.dart';

/// Abstract contract for the local weather cache.
///
/// The implementation uses SharedPreferences or a local database.
/// In tests, a fake replaces this with an in-memory map.
abstract class WeatherLocalDatasource {
  /// Cache weather data for a city.
  Future<void> cacheWeather(WeatherModel weather);

  /// Retrieve the last cached weather for [city], or null if not cached.
  Future<WeatherModel?> getLastWeather(String city);

  /// Get the list of favorite cities.
  Future<List<String>> getFavoriteCities();

  /// Add a city to favorites.
  Future<void> addFavoriteCity(String city);

  /// Remove a city from favorites.
  Future<void> removeFavoriteCity(String city);
}

// --------------------------------------------------------------------------
// Production implementation (uses SharedPreferences-style storage)
// --------------------------------------------------------------------------

/// Real implementation of [WeatherLocalDatasource].
///
/// Not used in tests — the fake replaces it entirely.
class WeatherLocalDatasourceImpl implements WeatherLocalDatasource {
  @override
  Future<void> cacheWeather(WeatherModel weather) async {
    throw UnimplementedError('Real cache not implemented — use fake in tests');
  }

  @override
  Future<WeatherModel?> getLastWeather(String city) async {
    throw UnimplementedError('Real cache not implemented — use fake in tests');
  }

  @override
  Future<List<String>> getFavoriteCities() async {
    throw UnimplementedError('Real cache not implemented — use fake in tests');
  }

  @override
  Future<void> addFavoriteCity(String city) async {
    throw UnimplementedError('Real cache not implemented — use fake in tests');
  }

  @override
  Future<void> removeFavoriteCity(String city) async {
    throw UnimplementedError('Real cache not implemented — use fake in tests');
  }
}
