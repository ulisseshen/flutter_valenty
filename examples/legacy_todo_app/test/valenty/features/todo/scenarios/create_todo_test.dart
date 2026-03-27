// =============================================================================
// CREATE TODO ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Todo App — Create Todo
//
// These scenarios test TodoService.createTodo() through the REAL singleton
// with FAKE dependencies.
//
// QA Scenarios:
//
//   1. "Given the API accepts new todos,
//       when I create a todo with title 'Learn Valenty',
//       then the created todo should have that title and not be completed"
//
// =============================================================================

import 'package:test/test.dart';

import '../todo_scenario.dart';

void main() {
  group('Create Todo', () {
    // --- Scenario 1: Create a new todo ---------------------------------------
    TodoScenario('should create a new todo via API')
        .given
        .apiTodos()
            .withCreateEnabled()
        .when
        .createTodo()
            .withTitle('Learn Valenty')
        .then
        .shouldSucceed()
        .and
        .todo()
            .hasTitle('Learn Valenty')
            .isCompleted(false)
        .run();

    // --- Scenario 2: Created todo starts as not completed ---------------------
    TodoScenario('should create todo with completed=false by default')
        .given
        .apiTodos()
            .withCreateEnabled()
        .when
        .createTodo()
            .withTitle('New task')
        .then
        .shouldSucceed()
        .and
        .todo()
            .isCompleted(false)
        .run();

    // --- Scenario 3: Create todo with long title ------------------------------
    TodoScenario('should handle long todo titles')
        .given
        .apiTodos()
            .withCreateEnabled()
        .when
        .createTodo()
            .withTitle('This is a very long todo title that describes a complex task requiring multiple steps to complete')
        .then
        .shouldSucceed()
        .and
        .todo()
            .hasTitle('This is a very long todo title that describes a complex task requiring multiple steps to complete')
            .isCompleted(false)
        .run();
  });
}
