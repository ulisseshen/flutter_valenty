import '../../../../core/usecases/usecase.dart';
import '../repositories/weather_repository.dart';

/// Use case: get the list of favorite cities.
class GetFavoriteCities extends UseCase<List<String>, NoParams> {
  GetFavoriteCities(this._repository);

  final WeatherRepository _repository;

  @override
  Future<List<String>> call(NoParams params) {
    return _repository.getFavoriteCities();
  }
}
