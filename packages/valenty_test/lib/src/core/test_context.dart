/// Key-value context passed between Given/When/Then steps.
class TestContext {
  final Map<String, dynamic> _values = {};

  /// Store a value by key.
  void set<T>(String key, T value) {
    _values[key] = value;
  }

  /// Retrieve a typed value by key.
  T get<T>(String key) {
    final value = _values[key];
    if (value == null) {
      throw StateError('No value found for key "$key" in TestContext.');
    }
    if (value is! T) {
      throw StateError(
        'Value for key "$key" is ${value.runtimeType}, expected $T.',
      );
    }
    return value;
  }

  /// Check if a key exists.
  bool has(String key) => _values.containsKey(key);

  /// Clear all values.
  void clear() => _values.clear();
}
