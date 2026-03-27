import 'package:clean_arch_weather_example/features/weather/data/datasources/weather_local_datasource.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';

/// In-memory fake for [WeatherLocalDatasource].
///
/// Stores cached weather and favorite cities in simple maps/lists,
/// simulating SharedPreferences or SQLite without real I/O.
class FakeWeatherLocalDatasource implements WeatherLocalDatasource {
  final Map<String, WeatherModel> _cache = {};
  final List<String> _favoriteCities = [];

  /// Pre-populate the cache (used in Given phase).
  void seedCache(WeatherModel weather) {
    _cache[weather.city.toLowerCase()] = weather;
  }

  /// Pre-populate favorite cities (used in Given phase).
  void seedFavoriteCity(String city) {
    if (!_favoriteCities.contains(city)) {
      _favoriteCities.add(city);
    }
  }

  @override
  Future<void> cacheWeather(WeatherModel weather) async {
    _cache[weather.city.toLowerCase()] = weather;
  }

  @override
  Future<WeatherModel?> getLastWeather(String city) async {
    return _cache[city.toLowerCase()];
  }

  @override
  Future<List<String>> getFavoriteCities() async {
    return List.unmodifiable(_favoriteCities);
  }

  @override
  Future<void> addFavoriteCity(String city) async {
    if (!_favoriteCities.contains(city)) {
      _favoriteCities.add(city);
    }
  }

  @override
  Future<void> removeFavoriteCity(String city) async {
    _favoriteCities.remove(city);
  }
}
