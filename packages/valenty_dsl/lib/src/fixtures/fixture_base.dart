/// Base class for test fixtures.
/// Provides standard creation methods for test data.
abstract class FixtureBase<T> {
  /// Create a single instance with default values.
  T create();

  /// Create multiple instances.
  List<T> createMany(int count) {
    return List.generate(count, (_) => create());
  }
}
