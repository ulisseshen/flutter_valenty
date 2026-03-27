// =============================================================================
// FETCH TODOS ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Todo App — Fetch Todos
//
// These scenarios test TodoService.fetchTodos() through the REAL singleton
// with FAKE dependencies injected via @visibleForTesting factories.
//
// The TodoScenario automatically creates a TodoTestEnvironment that:
// - Overrides singleton factories with fakes (in the Given step)
// - Restores original factories after each test (via addTearDown)
//
// QA Scenarios:
//
//   1. "Given the API returns 2 todos,
//       when I fetch todos,
//       then I should see 2 todos with correct titles"
//
//   2. "Given the API returns a 503 error AND cached todos exist,
//       when I fetch todos,
//       then I should see the cached todos (fallback)"
//
//   3. "Given the API returns a 503 error AND no cached todos exist,
//       when I fetch todos,
//       then I should see an empty list"
//
// =============================================================================

import 'package:test/test.dart';

import '../todo_scenario.dart';

void main() {
  group('Fetch Todos', () {
    // --- Scenario 1: Fetch from API ------------------------------------------
    TodoScenario('should fetch todos from API')
        .given
        .apiTodos()
            .withTodo(id: '1', title: 'Buy milk', completed: false)
            .withTodo(id: '2', title: 'Walk dog', completed: true)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .hasTodoCount(2)
            .containsTodo(title: 'Buy milk')
            .containsTodo(title: 'Walk dog')
        .run();

    // --- Scenario 2: Fallback to cache on API error --------------------------
    TodoScenario('should fallback to cached todos when API fails')
        .given
        .apiError()
            .withServerError(503)
        .and
        .cachedTodos()
            .withTodo(id: '1', title: 'Cached task', completed: false)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .hasTodoCount(1)
            .containsTodo(title: 'Cached task')
        .run();

    // --- Scenario 3: API error with empty cache ------------------------------
    TodoScenario('should return empty list when API fails and no cache')
        .given
        .apiError()
            .withServerError(503)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .isEmpty()
        .run();

    // --- Scenario 4: Fetch single todo -----------------------------------------
    TodoScenario('should fetch a single todo from API')
        .given
        .apiTodos()
            .withTodo(id: '1', title: 'Single task', completed: false)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .hasTodoCount(1)
            .containsTodo(title: 'Single task')
        .run();

    // --- Scenario 5: Fetch todos preserves completion status -------------------
    TodoScenario('should preserve completed status from API')
        .given
        .apiTodos()
            .withTodo(id: '1', title: 'Done task', completed: true)
            .withTodo(id: '2', title: 'Pending task', completed: false)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .hasTodoCount(2)
            .containsTodo(title: 'Done task')
            .containsTodo(title: 'Pending task')
        .run();

    // --- Scenario 6: Fetch from cache after previous API success ---------------
    TodoScenario('should use cached todos from previous successful fetch')
        .given
        .cachedTodos()
            .withTodo(id: '1', title: 'Previously fetched', completed: false)
        .and
        .apiError()
            .withServerError(500)
        .when
        .fetchTodos()
        .then
        .shouldSucceed()
        .and
        .todoList()
            .hasTodoCount(1)
            .containsTodo(title: 'Previously fetched')
        .run();
  });
}
