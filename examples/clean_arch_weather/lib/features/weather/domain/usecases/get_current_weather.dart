import '../../../../core/usecases/usecase.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

/// Use case: get current weather for a city.
///
/// Single responsibility — delegates to the [WeatherRepository].
class GetCurrentWeather extends UseCase<Weather, String> {
  GetCurrentWeather(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Weather> call(String city) {
    return _repository.getCurrentWeather(city);
  }
}
