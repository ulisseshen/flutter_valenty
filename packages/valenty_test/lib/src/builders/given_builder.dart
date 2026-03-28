import '../core/phantom_types.dart';
import '../core/scenario_builder.dart';

/// Base class for the Given phase of a scenario.
///
/// Subclass this to define domain-specific precondition methods.
/// Each method typically returns a [DomainObjectBuilder] for fluent
/// configuration of that domain object.
///
/// Example:
/// ```dart
/// class OrderGivenBuilder extends GivenBuilder {
///   OrderGivenBuilder(super.scenario);
///
///   ProductGivenBuilder product() => ProductGivenBuilder(scenario);
///   CouponGivenBuilder coupon() => CouponGivenBuilder(scenario);
/// }
/// ```
abstract class GivenBuilder {
  /// Create a GivenBuilder wrapping the scenario in [NeedsWhen] state.
  GivenBuilder(this._scenario);

  final ScenarioBuilder<NeedsWhen> _scenario;

  /// Access the underlying scenario builder.
  ///
  /// Subclasses and domain object builders use this to register steps.
  ScenarioBuilder<NeedsWhen> get scenario => _scenario;
}
