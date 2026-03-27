import 'package:legacy_todo_app_example/models/todo.dart';
import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import 'todo_then_builder.dart';

/// Fluent assertion builder for single todo properties.
///
/// Available assertions:
/// - `.isCompleted(bool)` — assert the completion status
/// - `.hasTitle(String)` — assert the title
/// - `.hasId(String)` — assert the ID
///
/// Chain with:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class TodoAssertionBuilder extends AssertionBuilder {
  TodoAssertionBuilder(super.scenario);

  /// Assert the todo has the expected completion status.
  TodoAssertionBuilder isCompleted(bool expected) {
    addAssertionStep((ctx) {
      final todo = ctx.get<Todo>('todo');
      expect(
        todo.completed,
        equals(expected),
        reason: 'Expected todo.completed to be $expected',
      );
    });
    return this;
  }

  /// Assert the todo has the expected title.
  TodoAssertionBuilder hasTitle(String expected) {
    addAssertionStep((ctx) {
      final todo = ctx.get<Todo>('todo');
      expect(
        todo.title,
        equals(expected),
        reason: 'Expected todo title to be "$expected"',
      );
    });
    return this;
  }

  /// Assert the todo has the expected ID.
  TodoAssertionBuilder hasId(String expected) {
    addAssertionStep((ctx) {
      final todo = ctx.get<Todo>('todo');
      expect(
        todo.id,
        equals(expected),
        reason: 'Expected todo ID to be "$expected"',
      );
    });
    return this;
  }

  /// Add more assertions.
  TodoAndThenBuilder get and => TodoAndThenBuilder(currentScenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(currentScenario);
}
