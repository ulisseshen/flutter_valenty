// =============================================================================
// COMPLETE TODO ACCEPTANCE TESTS
// =============================================================================
//
// Domain: Legacy Todo App — Complete Todo
//
// These scenarios test TodoService.completeTodo() through the REAL singleton
// with FAKE dependencies. Verifies both the todo state change AND the
// notification side effect.
//
// QA Scenarios:
//
//   1. "Given a todo exists,
//       when I complete it,
//       then it should be marked as completed AND a notification is sent"
//
// =============================================================================

import 'package:test/test.dart';

import '../todo_scenario.dart';

void main() {
  group('Complete Todo', () {
    // --- Scenario 1: Complete a todo -----------------------------------------
    TodoScenario('should mark todo as completed and send notification')
        .given
        .apiTodos()
            .withTodo(id: '1', title: 'Buy milk', completed: false)
        .when
        .completeTodo()
            .withTodoId('1')
        .then
        .shouldSucceed()
        .and
        .todo()
            .isCompleted(true)
            .hasTitle('Buy milk')
        .and
        .notification()
            .wasSent()
            .containsMessage('Buy milk')
        .run();

    // --- Scenario 2: Complete preserves todo ID --------------------------------
    TodoScenario('should return the completed todo with correct ID')
        .given
        .apiTodos()
            .withTodo(id: 'abc-123', title: 'Clean house', completed: false)
        .when
        .completeTodo()
            .withTodoId('abc-123')
        .then
        .shouldSucceed()
        .and
        .todo()
            .hasId('abc-123')
            .hasTitle('Clean house')
            .isCompleted(true)
        .run();

    // --- Scenario 3: Notification message includes todo title ------------------
    TodoScenario('should include todo title in notification message')
        .given
        .apiTodos()
            .withTodo(id: '1', title: 'Deploy to production', completed: false)
        .when
        .completeTodo()
            .withTodoId('1')
        .then
        .shouldSucceed()
        .and
        .notification()
            .wasSent()
            .containsMessage('Deploy to production')
        .run();
  });
}
