/// Phantom types for compile-time scenario state enforcement.
/// These types are never instantiated - they exist only as type parameters.
sealed class ScenarioState {}

/// Initial state - only `given()` is available.
final class NeedsGiven extends ScenarioState {}

/// After given - `when()` and `and()` (for additional givens) are available.
final class NeedsWhen extends ScenarioState {}

/// After when - `then()` is available.
final class NeedsThen extends ScenarioState {}

/// After then - `run()` and `and()` (for additional assertions) are available.
final class ReadyToRun extends ScenarioState {}
