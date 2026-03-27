import 'package:test/test.dart' show addTearDown;
import 'package:valenty_dsl/valenty_dsl.dart';

import 'builders/given/todo_given_builder.dart';
import 'setup/todo_test_environment.dart';

/// Entry point for Todo feature acceptance tests.
///
/// Automatically creates a [TodoTestEnvironment] and wires it into
/// the test context as the first Given step. The environment is
/// applied (singleton overrides activated) when the test runs,
/// and restored via addTearDown after the test body completes.
///
/// Usage:
/// ```dart
/// TodoScenario('should fetch todos from API')
///     .given
///     .apiTodos()
///         .withTodo(id: '1', title: 'Buy milk', completed: false)
///     .when
///     .fetchTodos()
///     .then
///     .shouldSucceed()
///     .run();
/// ```
class TodoScenario extends FeatureScenario<TodoGivenBuilder> {
  TodoScenario(super.description);

  @override
  TodoGivenBuilder createGivenBuilder(
    ScenarioBuilder<NeedsWhen> scenario,
  ) {
    // Register an initial step that creates and applies the test environment.
    // This runs inside the test body, so singletons are safely scoped per test.
    final withEnv = scenario.appendStep(
      StepRecord(
        phase: StepPhase.given,
        action: (ctx) {
          final env = TodoTestEnvironment()..apply();
          ctx.set('_testEnv', env);
          // Restore singletons after the test completes
          addTearDown(() => env.restore());
        },
      ),
    );
    return TodoGivenBuilder(withEnv);
  }
}
