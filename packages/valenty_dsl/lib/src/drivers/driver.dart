/// Base interface for test drivers.
/// Drivers provide the mechanism to interact with the system under test.
abstract interface class Driver {
  /// Set up the driver before tests.
  Future<void> setUp();

  /// Tear down the driver after tests.
  Future<void> tearDown();
}
