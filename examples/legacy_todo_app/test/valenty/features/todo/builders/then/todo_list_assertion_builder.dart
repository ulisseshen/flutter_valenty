import 'package:legacy_todo_app_example/models/todo.dart';
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'todo_then_builder.dart';

/// Fluent assertion builder for todo list properties.
///
/// Available assertions:
/// - `.hasTodoCount(int)` — assert the number of todos
/// - `.containsTodo(title:)` — assert a todo with the given title exists
/// - `.isEmpty()` — assert the list is empty
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class TodoListAssertionBuilder extends AssertionBuilder {
  TodoListAssertionBuilder(super.scenario);

  /// Assert the todo list has the expected number of items.
  TodoListAssertionBuilder hasTodoCount(int expected) {
    addAssertionStep((ctx) {
      final todos = ctx.get<List<Todo>>('todoList');
      expect(
        todos.length,
        equals(expected),
        reason: 'Expected $expected todos, got ${todos.length}',
      );
    });
    return this;
  }

  /// Assert the todo list contains a todo with the given title.
  TodoListAssertionBuilder containsTodo({required String title}) {
    addAssertionStep((ctx) {
      final todos = ctx.get<List<Todo>>('todoList');
      expect(
        todos.any((t) => t.title == title),
        isTrue,
        reason: 'Expected todo list to contain a todo with title "$title"',
      );
    });
    return this;
  }

  /// Assert the todo list is empty.
  TodoListAssertionBuilder isEmpty() {
    addAssertionStep((ctx) {
      final todos = ctx.get<List<Todo>>('todoList');
      expect(
        todos,
        hasLength(0),
        reason: 'Expected todo list to be empty',
      );
    });
    return this;
  }

  /// Add more assertions.
  TodoAndThenBuilder get and => TodoAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
