import 'package:valenty_test/valenty_test.dart';

import 'fetch_todos_when_builder.dart';
import 'complete_todo_when_builder.dart';
import 'create_todo_when_builder.dart';

/// WhenBuilder for the Todo feature.
///
/// Provides actions available in the When phase:
/// - `.fetchTodos()` — fetch all todos
/// - `.completeTodo()` — mark a todo as completed
/// - `.createTodo()` — create a new todo
class TodoWhenBuilder extends WhenBuilder {
  TodoWhenBuilder(super.scenario);

  /// Trigger the "fetch todos" action.
  FetchTodosWhenBuilder fetchTodos() => FetchTodosWhenBuilder(scenario);

  /// Trigger the "complete todo" action.
  CompleteTodoWhenBuilder completeTodo() => CompleteTodoWhenBuilder(scenario);

  /// Trigger the "create todo" action.
  CreateTodoWhenBuilder createTodo() => CreateTodoWhenBuilder(scenario);
}
