/// Infrastructure setup that runs before and after scenarios.
///
/// Use `TestEnvironment` to configure external system fakes, override
/// singleton factories, and set up any infrastructure that is NOT part
/// of the business scenario (Given/When/Then).
///
/// ## Why separate from Given?
///
/// Given is for **domain preconditions** ("given a product with price $20").
/// Infrastructure setup is for **test plumbing** ("stub the backend API",
/// "override the singleton factory", "fix the clock").
///
/// ## Usage
///
/// ```dart
/// final env = TestEnvironment()
///     .setup(() => OrderService.httpClientFactory = () => fakeHttp)
///     .setup(() => AuthManager.instance.setForTesting(userId: 'u1'))
///     .teardown(() => OrderService.httpClientFactory = () => RealHttpClient())
///     .teardown(() => AuthManager.instance.resetForTesting());
///
/// OrderScenario('should calculate total', env)
///     .given
///     .product().withUnitPrice(20.00)
///     .when
///     .placeOrder().withQuantity(5)
///     .then
///     .order().hasTotalPrice(100.00)
///     .run();
/// ```
///
/// ## Reusable across scenarios
///
/// ```dart
/// final env = TestEnvironment()
///     .setup(() => MyService.dep = fakeDep)
///     .teardown(() => MyService.dep = realDep);
///
/// // Same environment, multiple scenarios
/// MyScenario('test 1', env).given...run();
/// MyScenario('test 2', env).given...run();
/// ```
class TestEnvironment {
  /// Reserved key used to store the environment in TestContext.
  static const contextKey = '__valenty_test_environment__';

  final List<void Function()> _setups = [];
  final List<void Function()> _teardowns = [];
  final List<Future<void> Function()> _asyncSetups = [];
  final List<Future<void> Function()> _asyncTeardowns = [];

  /// Register a synchronous setup action.
  ///
  /// Runs before the scenario steps execute. Use for overriding
  /// singleton factories, configuring fakes, clearing caches.
  TestEnvironment setup(void Function() fn) {
    _setups.add(fn);
    return this;
  }

  /// Register an async setup action.
  ///
  /// Runs before the scenario steps execute. Use for async
  /// initialization that must complete before the test runs.
  TestEnvironment setupAsync(Future<void> Function() fn) {
    _asyncSetups.add(fn);
    return this;
  }

  /// Register a synchronous teardown action.
  ///
  /// Runs after the scenario steps execute (even if the test fails).
  /// Use for restoring original singleton factories, clearing state.
  TestEnvironment teardown(void Function() fn) {
    _teardowns.add(fn);
    return this;
  }

  /// Register an async teardown action.
  ///
  /// Runs after the scenario steps execute (even if the test fails).
  TestEnvironment teardownAsync(Future<void> Function() fn) {
    _asyncTeardowns.add(fn);
    return this;
  }

  /// Apply all setup actions (called by ScenarioRunner before steps).
  Future<void> apply() async {
    for (final fn in _setups) {
      fn();
    }
    for (final fn in _asyncSetups) {
      await fn();
    }
  }

  /// Restore all teardown actions (called by ScenarioRunner after steps).
  Future<void> restore() async {
    for (final fn in _teardowns) {
      fn();
    }
    for (final fn in _asyncTeardowns) {
      await fn();
    }
  }

  /// Whether this environment has any setup or teardown actions.
  bool get isEmpty =>
      _setups.isEmpty &&
      _asyncSetups.isEmpty &&
      _teardowns.isEmpty &&
      _asyncTeardowns.isEmpty;
}
