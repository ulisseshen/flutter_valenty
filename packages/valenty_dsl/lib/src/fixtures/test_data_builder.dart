/// Builder pattern for creating test data.
/// Subclass to define builders for your domain objects.
abstract class TestDataBuilder<T> {
  /// Build the final object.
  T build();

  /// Reset the builder to defaults.
  void reset();
}
