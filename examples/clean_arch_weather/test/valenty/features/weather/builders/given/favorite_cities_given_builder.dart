import 'package:valenty_test/valenty_test.dart';

import '../when/weather_when_builder.dart';
import 'weather_given_builder.dart';

/// Builder for pre-populating favorite cities in the Given phase.
///
/// Available methods:
/// - `.withCity(String)` — add a city to favorites
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class FavoriteCitiesGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  FavoriteCitiesGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<String> _cities = [];

  FavoriteCitiesGivenBuilder withCity(String city) {
    _cities.add(city);
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('favoriteCities')
        ? ctx.get<List<String>>('favoriteCities')
        : <String>[];

    ctx.set('favoriteCities', [...existing, ..._cities]);
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
