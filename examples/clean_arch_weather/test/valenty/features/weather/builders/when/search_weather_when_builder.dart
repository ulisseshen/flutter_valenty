import 'package:clean_arch_weather_example/core/error/exceptions.dart';
import 'package:clean_arch_weather_example/features/weather/data/models/weather_model.dart';
import 'package:clean_arch_weather_example/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:clean_arch_weather_example/features/weather/domain/entities/weather.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../fakes/fake_weather_local_datasource.dart';
import '../../fakes/fake_weather_remote_datasource.dart';
import '../then/weather_then_builder.dart';

/// Builder for the "search current weather" use case.
///
/// Available methods:
/// - `.forCity(String)` — set the city to search for
/// - `.then` — transition to Then phase
class SearchWeatherWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  SearchWeatherWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _city = '';

  SearchWeatherWhenBuilder forCity(String city) {
    _city = city;
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
    } else {
      final apiResponses = ctx.has('apiWeatherResponses')
          ? ctx.get<List<WeatherModel>>('apiWeatherResponses')
          : <WeatherModel>[];
      for (final weather in apiResponses) {
        remoteDatasource.addWeather(weather);
      }
    }

    // Configure local datasource with cached data
    final cachedData = ctx.has('cachedWeatherData')
        ? ctx.get<List<WeatherModel>>('cachedWeatherData')
        : <WeatherModel>[];
    for (final weather in cachedData) {
      localDatasource.seedCache(weather);
    }

    // Configure favorite cities
    final favoriteCities = ctx.has('favoriteCities')
        ? ctx.get<List<String>>('favoriteCities')
        : <String>[];
    for (final city in favoriteCities) {
      localDatasource.seedFavoriteCity(city);
    }

    // 2. Use the REAL repository with FAKE datasources
    final repository = WeatherRepositoryImpl(
      remoteDatasource: remoteDatasource,
      localDatasource: localDatasource,
    );

    // 3. Execute the use case synchronously in context
    // We store a closure that will be awaited by the scenario runner
    ctx.set('_weatherAction', () async {
      try {
        final weather = await repository.getCurrentWeather(_city);
        return _WeatherResult.success(weather);
      } on CacheException catch (e) {
        return _WeatherResult.failure(e.message);
      }
    });
  }

  /// Transition to Then phase.
  WeatherThenBuilder get then {
    final finalized = finalizeStep();

    // Add an execution step that runs the async action
    final withExecution = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final action =
              ctx.get<Future<_WeatherResult> Function()>('_weatherAction');
          final result = await action();
          ctx.set('weatherResult', result);
          if (result.isSuccess) {
            ctx.set('weather', result.weather!);
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

/// Internal result wrapper for async weather operations.
class _WeatherResult {
  _WeatherResult.success(this.weather)
      : isSuccess = true,
        error = null;

  _WeatherResult.failure(this.error)
      : isSuccess = false,
        weather = null;

  final bool isSuccess;
  final Weather? weather;
  final String? error;
}
