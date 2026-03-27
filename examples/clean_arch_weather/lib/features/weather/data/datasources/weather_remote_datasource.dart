import '../../../../core/error/exceptions.dart';
import '../models/forecast_model.dart';
import '../models/weather_model.dart';

/// Abstract contract for the remote weather data source.
///
/// The implementation calls a real HTTP API (e.g. OpenWeatherMap).
/// In tests, a fake replaces this with configurable responses.
abstract class WeatherRemoteDatasource {
  /// Fetch current weather for [city] from the API.
  ///
  /// Throws [ServerException] on non-2xx responses.
  Future<WeatherModel> getCurrentWeather(String city);

  /// Fetch a multi-day forecast for [city] from the API.
  ///
  /// Throws [ServerException] on non-2xx responses.
  Future<ForecastModel> getForecast(String city, {int days = 5});
}

// --------------------------------------------------------------------------
// Production implementation (uses http package)
// --------------------------------------------------------------------------

/// Real HTTP implementation of [WeatherRemoteDatasource].
///
/// Not used in tests — the fake replaces it entirely.
class WeatherRemoteDatasourceImpl implements WeatherRemoteDatasource {
  WeatherRemoteDatasourceImpl({
    required this.apiKey,
    this.baseUrl = 'https://api.openweathermap.org/data/2.5',
  });

  final String apiKey;
  final String baseUrl;

  @override
  Future<WeatherModel> getCurrentWeather(String city) async {
    // In a real app this would use the http package:
    // final response = await client.get(Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey'));
    throw UnimplementedError(
      'Real HTTP call not implemented — use fake in tests',
    );
  }

  @override
  Future<ForecastModel> getForecast(String city, {int days = 5}) async {
    throw UnimplementedError(
      'Real HTTP call not implemented — use fake in tests',
    );
  }
}
