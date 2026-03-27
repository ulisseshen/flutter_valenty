import '../../../../core/error/exceptions.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_local_datasource.dart';
import '../datasources/weather_remote_datasource.dart';

/// Concrete implementation of [WeatherRepository].
///
/// This is the interesting part for testing: it coordinates between
/// the remote and local datasources with fallback logic.
///
/// In tests, we use the REAL [WeatherRepositoryImpl] with FAKE datasources.
/// This validates the actual repository logic (caching, fallback) without
/// hitting real APIs or storage.
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  final WeatherRemoteDatasource remoteDatasource;
  final WeatherLocalDatasource localDatasource;

  @override
  Future<Weather> getCurrentWeather(String city) async {
    try {
      final weather = await remoteDatasource.getCurrentWeather(city);
      await localDatasource.cacheWeather(weather);
      return weather;
    } on ServerException {
      // Fallback to cache when API fails
      final cached = await localDatasource.getLastWeather(city);
      if (cached != null) return cached;
      throw CacheException('No cached data for $city');
    }
  }

  @override
  Future<Forecast> getForecast(String city, {int days = 5}) async {
    try {
      return await remoteDatasource.getForecast(city, days: days);
    } on ServerException {
      throw CacheException('No cached forecast for $city');
    }
  }

  @override
  Future<List<String>> getFavoriteCities() {
    return localDatasource.getFavoriteCities();
  }

  @override
  Future<void> addFavoriteCity(String city) {
    return localDatasource.addFavoriteCity(city);
  }

  @override
  Future<void> removeFavoriteCity(String city) {
    return localDatasource.removeFavoriteCity(city);
  }
}
