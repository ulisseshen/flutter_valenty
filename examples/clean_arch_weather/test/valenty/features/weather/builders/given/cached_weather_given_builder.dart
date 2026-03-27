import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../when/weather_when_builder.dart';
import 'weather_given_builder.dart';

/// Builder for pre-populating the local cache in the Given phase.
///
/// Available methods:
/// - `.withCity(String)` — set the city name for cached data
/// - `.withTemperature(double)` — set cached temperature
/// - `.withDescription(String)` — set cached description
/// - `.withHumidity(int)` — set cached humidity
/// - `.withWindSpeed(double)` — set cached wind speed
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class CachedWeatherGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CachedWeatherGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _city = 'Unknown';
  double _temperature = 20.0;
  String _description = 'Clear';
  int _humidity = 50;
  double _windSpeed = 5.0;

  CachedWeatherGivenBuilder withCity(String city) {
    _city = city;
    return this;
  }

  CachedWeatherGivenBuilder withTemperature(double temperature) {
    _temperature = temperature;
    return this;
  }

  CachedWeatherGivenBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  CachedWeatherGivenBuilder withHumidity(int humidity) {
    _humidity = humidity;
    return this;
  }

  CachedWeatherGivenBuilder withWindSpeed(double windSpeed) {
    _windSpeed = windSpeed;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('cachedWeatherData')
        ? ctx.get<List<WeatherModel>>('cachedWeatherData')
        : <WeatherModel>[];

    existing.add(
      WeatherModel(
        city: _city,
        temperature: _temperature,
        description: _description,
        humidity: _humidity,
        windSpeed: _windSpeed,
      ),
    );

    ctx.set('cachedWeatherData', existing);
  }

  /// Transition to When phase.
  WeatherWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return WeatherWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  WeatherGivenBuilder get and {
    final finalized = finalizeStep();
    return WeatherGivenBuilder(finalized);
  }
}
