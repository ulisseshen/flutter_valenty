import 'package:clean_arch_weather_example/core/error/exceptions.dart';
import 'package:clean_arch_weather_example/features/weather/data/datasources/weather_remote_datasource.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/forecast_model.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';

/// In-memory fake for [WeatherRemoteDatasource].
///
/// Configurable to return specific weather data or throw errors,
/// simulating API responses without HTTP calls.
class FakeWeatherRemoteDatasource implements WeatherRemoteDatasource {
  final Map<String, WeatherModel> _weatherByCity = {};
  final Map<String, ForecastModel> _forecastByCity = {};

  ServerException? _serverError;

  /// Configure the fake to return weather for a specific city.
  void addWeather(WeatherModel weather) {
    _weatherByCity[weather.city.toLowerCase()] = weather;
  }

  /// Configure the fake to return a forecast for a specific city.
  void addForecast(ForecastModel forecast) {
    _forecastByCity[forecast.city.toLowerCase()] = forecast;
  }

  /// Configure the fake to throw a [ServerException] for all calls.
  void configureServerError({required int statusCode, String? message}) {
    _serverError = ServerException(
      message ?? 'Server error',
      statusCode: statusCode,
    );
  }

  /// Clear the server error so calls succeed again.
  void clearServerError() {
    _serverError = null;
  }

  @override
  Future<WeatherModel> getCurrentWeather(String city) async {
    if (_serverError != null) throw _serverError!;

    final weather = _weatherByCity[city.toLowerCase()];
    if (weather == null) {
      throw ServerException('City not found: $city', statusCode: 404);
    }
    return weather;
  }

  @override
  Future<ForecastModel> getForecast(String city, {int days = 5}) async {
    if (_serverError != null) throw _serverError!;

    final forecast = _forecastByCity[city.toLowerCase()];
    if (forecast == null) {
      throw ServerException('Forecast not found for: $city', statusCode: 404);
    }

    // Trim to requested number of days
    final trimmedDays = forecast.days.take(days).toList();
    return ForecastModel(city: forecast.city, days: trimmedDays);
  }
}
