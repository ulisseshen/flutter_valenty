import '../../../../core/usecases/usecase.dart';
import '../entities/forecast.dart';
import '../repositories/weather_repository.dart';

/// Parameters for the [GetForecast] use case.
class ForecastParams {
  const ForecastParams({required this.city, this.days = 5});

  final String city;
  final int days;
}

/// Use case: get a multi-day forecast for a city.
class GetForecast extends UseCase<Forecast, ForecastParams> {
  GetForecast(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Forecast> call(ForecastParams params) {
    return _repository.getForecast(params.city, days: params.days);
  }
}
