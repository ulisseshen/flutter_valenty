import '../../domain/entities/weather.dart';

/// Data model that extends [Weather] with JSON serialization.
///
/// This is the Entity vs Model separation pattern:
/// - [Weather] (domain) — pure, no JSON, no dependencies
/// - [WeatherModel] (data) — knows about JSON, used for API/cache
class WeatherModel extends Weather {
  const WeatherModel({
    required super.city,
    required super.temperature,
    required super.description,
    required super.humidity,
    required super.windSpeed,
  });

  /// Create from OpenWeatherMap-style JSON response.
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'] as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      description: (json['weather'] as List).first['description'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  /// Create from a domain [Weather] entity (for caching).
  factory WeatherModel.fromEntity(Weather weather) {
    return WeatherModel(
      city: weather.city,
      temperature: weather.temperature,
      description: weather.description,
      humidity: weather.humidity,
      windSpeed: weather.windSpeed,
    );
  }

  /// Convert to JSON for cache storage.
  Map<String, dynamic> toJson() {
    return {
      'name': city,
      'main': {
        'temp': temperature,
        'humidity': humidity,
      },
      'weather': [
        {'description': description},
      ],
      'wind': {
        'speed': windSpeed,
      },
    };
  }
}
