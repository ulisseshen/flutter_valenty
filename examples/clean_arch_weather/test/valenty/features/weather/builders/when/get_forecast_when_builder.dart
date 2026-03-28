import 'package:clean_arch_weather_example/core/error/exceptions.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/forecast_model.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';
import 'package:clean_arch_weather_example/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:clean_arch_weather_example/features/weather/domain/entities/forecast.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../fakes/fake_weather_local_datasource.dart';
import '../../fakes/fake_weather_remote_datasource.dart';
import '../then/weather_then_builder.dart';

/// Builder for the "get forecast" use case.
///
/// Available methods:
/// - `.forCity(String)` — set the city
/// - `.forDays(int)` — set number of forecast days
/// - `.then` — transition to Then phase
class GetForecastWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  GetForecastWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _city = '';
  int _days = 5;

  GetForecastWhenBuilder forCity(String city) {
    _city = city;
    return this;
  }

  GetForecastWhenBuilder forDays(int days) {
    _days = days;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // 1. Build fakes from Given-phase context
    final remoteDatasource = FakeWeatherRemoteDatasource();
    final localDatasource = FakeWeatherLocalDatasource();

    // Configure remote datasource
    final hasServerError = ctx.has('apiHasServerError')
        ? ctx.get<bool>('apiHasServerError')
        : false;

    if (hasServerError) {
      final errorCode = ctx.get<int>('apiServerErrorCode');
      remoteDatasource.configureServerError(statusCode: errorCode);
    }

    // Add any configured forecasts
    final forecasts = ctx.has('apiForecastResponses')
        ? ctx.get<List<ForecastModel>>('apiForecastResponses')
        : <ForecastModel>[];
    for (final forecast in forecasts) {
      remoteDatasource.addForecast(forecast);
    }

    // Configure local datasource with cached data
    final cachedData = ctx.has('cachedWeatherData')
        ? ctx.get<List<WeatherModel>>('cachedWeatherData')
        : <WeatherModel>[];
    for (final weather in cachedData) {
      localDatasource.seedCache(weather);
    }

    // 2. Use the REAL repository with FAKE datasources
    final repository = WeatherRepositoryImpl(
      remoteDatasource: remoteDatasource,
      localDatasource: localDatasource,
    );

    final city = _city;
    final days = _days;

    ctx.set('_forecastAction', () async {
      try {
        final forecast = await repository.getForecast(city, days: days);
        return _ForecastResult.success(forecast);
      } on CacheException catch (e) {
        return _ForecastResult.failure(e.message);
      }
    });
  }

  /// Transition to Then phase.
  WeatherThenBuilder get then {
    final finalized = finalizeStep();

    final withExecution = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final action =
              ctx.get<Future<_ForecastResult> Function()>('_forecastAction');
          final result = await action();
          if (result.isSuccess) {
            ctx.set('forecast', result.forecast!);
            ctx.set('operationFailed', false);
          } else {
            ctx.set('operationFailed', true);
            ctx.set('operationError', result.error!);
          }
        },
      ),
    );

    final next = withExecution.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return WeatherThenBuilder(next);
  }
}

class _ForecastResult {
  _ForecastResult.success(this.forecast)
      : isSuccess = true,
        error = null;

  _ForecastResult.failure(this.error)
      : isSuccess = false,
        forecast = null;

  final bool isSuccess;
  final Forecast? forecast;
  final String? error;
}
