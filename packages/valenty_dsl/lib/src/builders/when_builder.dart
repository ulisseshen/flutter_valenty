import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the When phase of a scenario.
///
/// Subclass this to define domain-specific action/use-case methods.
/// Each method typically returns a [DomainObjectBuilder] for fluent
/// configuration of that action's parameters.
///
/// Example:
/// ```dart
/// class OrderWhenBuilder extends WhenBuilder {
///   OrderWhenBuilder(super.scenario);
///
///   PlaceOrderWhenBuilder placeOrder() => PlaceOrderWhenBuilder(scenario);
///   CancelOrderWhenBuilder cancelOrder() => CancelOrderWhenBuilder(scenario);
/// }
/// ```
abstract class WhenBuilder {
  /// Create a WhenBuilder wrapping the scenario in [NeedsThen] state.
  WhenBuilder(this._scenario);

  final ScenarioBuilder<NeedsThen> _scenario;

  /// Access the underlying scenario builder.
  ScenarioBuilder<NeedsThen> get scenario => _scenario;
}
