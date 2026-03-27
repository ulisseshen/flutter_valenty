/// A single day's forecast.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.temperatureHigh,
    required this.temperatureLow,
    required this.description,
  });

  /// The date this forecast is for.
  final DateTime date;

  /// High temperature in Celsius.
  final double temperatureHigh;

  /// Low temperature in Celsius.
  final double temperatureLow;

  /// Human-readable weather description.
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyForecast &&
          date == other.date &&
          temperatureHigh == other.temperatureHigh &&
          temperatureLow == other.temperatureLow &&
          description == other.description;

  @override
  int get hashCode =>
      Object.hash(date, temperatureHigh, temperatureLow, description);
}

/// Domain entity representing a multi-day weather forecast for a city.
class Forecast {
  const Forecast({
    required this.city,
    required this.days,
  });

  /// City name.
  final String city;

  /// List of daily forecasts.
  final List<DailyForecast> days;

  @override
  String toString() => 'Forecast(city: $city, days: ${days.length})';
}
