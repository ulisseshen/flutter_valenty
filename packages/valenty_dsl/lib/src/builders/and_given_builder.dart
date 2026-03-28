import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the And phase after Given (additional preconditions).
///
/// Structurally identical to [GivenBuilder]. Feature scenarios typically
/// reuse their GivenBuilder for `.and` after Given, but this base class
/// exists in case different behavior is needed.
abstract class AndGivenBuilder {
  /// Create an AndGivenBuilder wrapping the scenario in [NeedsWhen] state.
  AndGivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
