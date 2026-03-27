import '../../domain/entities/forecast.dart';

/// Data model that extends [Forecast] with JSON serialization.
class ForecastModel extends Forecast {
  const ForecastModel({
    required super.city,
    required super.days,
  });

  /// Create from OpenWeatherMap-style forecast JSON.
  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final city = json['city']['name'] as String;
    final list = json['list'] as List;

    final days = list.map((item) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as int) * 1000,
      );
      return DailyForecast(
        date: dt,
        temperatureHigh: (item['temp']['max'] as num).toDouble(),
        temperatureLow: (item['temp']['min'] as num).toDouble(),
        description: (item['weather'] as List).first['description'] as String,
      );
    }).toList();

    return ForecastModel(city: city, days: days);
  }

  /// Convert to JSON for cache storage.
  Map<String, dynamic> toJson() {
    return {
      'city': {'name': city},
      'list': days
          .map((d) => {
                'dt': d.date.millisecondsSinceEpoch ~/ 1000,
                'temp': {
                  'max': d.temperatureHigh,
                  'min': d.temperatureLow,
                },
                'weather': [
                  {'description': d.description},
                ],
              },)
          .toList(),
    };
  }
}
