import 'fixture_base.dart';

/// Mixin providing creation method patterns for fixtures.
mixin CreationMethods<T> on FixtureBase<T> {
  /// Create an instance with specific overrides.
  T createWith(T Function(T base) modifier) {
    return modifier(create());
  }
}
