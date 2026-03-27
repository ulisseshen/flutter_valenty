/// Domain entity representing current weather conditions for a city.
///
/// This is a pure domain object — no JSON serialization, no framework
/// dependencies. The data layer uses [WeatherModel] which extends this.
class Weather {
  const Weather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

  /// City name (e.g. 'London').
  final String city;

  /// Temperature in Celsius.
  final double temperature;

  /// Human-readable weather description (e.g. 'Cloudy').
  final String description;

  /// Humidity percentage (0-100).
  final int humidity;

  /// Wind speed in m/s.
  final double windSpeed;

  @override
  String toString() =>
      'Weather(city: $city, temp: $temperature, desc: $description, '
      'humidity: $humidity, wind: $windSpeed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Weather &&
          city == other.city &&
          temperature == other.temperature &&
          description == other.description &&
          humidity == other.humidity &&
          windSpeed == other.windSpeed;

  @override
  int get hashCode => Object.hash(city, temperature, description, humidity, windSpeed);
}
