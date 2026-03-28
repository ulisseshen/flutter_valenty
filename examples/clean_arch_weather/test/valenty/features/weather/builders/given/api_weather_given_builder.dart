import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';
import 'package:valenty_test/valenty_test.dart';

import '../when/weather_when_builder.dart';
import 'weather_given_builder.dart';

/// Builder for configuring what the remote API returns in the Given phase.
///
/// Available methods:
/// - `.withCity(String)` — set the city name for the response
/// - `.withTemperature(double)` — set temperature in Celsius
/// - `.withDescription(String)` — set weather description
/// - `.withHumidity(int)` — set humidity percentage
/// - `.withWindSpeed(double)` — set wind speed
/// - `.withServerError(int)` — configure API to fail with status code
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class ApiWeatherGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiWeatherGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _city = 'Unknown';
  double _temperature = 20.0;
  String _description = 'Clear';
  int _humidity = 50;
  double _windSpeed = 5.0;

  bool _hasServerError = false;
  int _serverErrorCode = 500;

  ApiWeatherGivenBuilder withCity(String city) {
    _city = city;
    return this;
  }

  ApiWeatherGivenBuilder withTemperature(double temperature) {
    _temperature = temperature;
    return this;
  }

  ApiWeatherGivenBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  ApiWeatherGivenBuilder withHumidity(int humidity) {
    _humidity = humidity;
    return this;
  }

  ApiWeatherGivenBuilder withWindSpeed(double windSpeed) {
    _windSpeed = windSpeed;
    return this;
  }

  /// Configure the API to fail with a specific HTTP status code.
  ApiWeatherGivenBuilder withServerError(int statusCode) {
    _hasServerError = true;
    _serverErrorCode = statusCode;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    if (_hasServerError) {
      ctx.set('apiHasServerError', true);
      ctx.set('apiServerErrorCode', _serverErrorCode);
    } else {
      ctx.set('apiHasServerError', false);

      // Accumulate API weather responses
      final existing = ctx.has('apiWeatherResponses')
          ? ctx.get<List<WeatherModel>>('apiWeatherResponses')
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

      ctx.set('apiWeatherResponses', existing);
    }
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
