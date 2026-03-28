import 'package:test/test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'todo_list_assertion_builder.dart';
import 'todo_assertion_builder.dart';
import 'notification_assertion_builder.dart';

/// ThenBuilder for the Todo feature.
///
/// Provides assertions available in the Then phase:
/// - `.shouldSucceed()` — assert the operation succeeded
/// - `.shouldFail()` — assert the operation failed
/// - `.todoList()` — fluent assertions on the todo list
/// - `.todo()` — fluent assertions on a single todo
/// - `.notification()` — fluent assertions on notifications
class TodoThenBuilder extends ThenBuilder {
  TodoThenBuilder(super.scenario);

  /// Assert the operation succeeded.
  TodoThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final failed = ctx.has('operationFailed')
          ? ctx.get<bool>('operationFailed')
          : false;
      expect(failed, isFalse, reason: 'Expected operation to succeed');
    });
    return TodoThenTerminal(next);
  }

  /// Assert the operation failed.
  TodoThenTerminal shouldFail() {
    final next = registerAssertion((ctx) {
      final failed = ctx.get<bool>('operationFailed');
      expect(failed, isTrue, reason: 'Expected operation to fail');
    });
    return TodoThenTerminal(next);
  }

  /// Start a fluent assertion chain for the todo list.
  TodoListAssertionBuilder todoList() => TodoListAssertionBuilder(scenario);

  /// Start a fluent assertion chain for a single todo.
  TodoAssertionBuilder todo() => TodoAssertionBuilder(scenario);

  /// Start a fluent assertion chain for notifications.
  NotificationAssertionBuilder notification() =>
      NotificationAssertionBuilder(scenario);
}

/// Terminal state after a simple assertion (shouldSucceed/shouldFail).
///
/// From here you can:
/// - `.and` — add more assertions
/// - `.run()` — execute the test
class TodoThenTerminal {
  TodoThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  /// Add more assertions.
  TodoAndThenBuilder get and => TodoAndThenBuilder(scenario);

  /// Execute the scenario as a test.
  void run() => ScenarioRunner.run(scenario);
}

/// AndThenBuilder for the Todo feature.
///
/// Allows chaining additional assertions after `.shouldSucceed()`.
class TodoAndThenBuilder extends AndThenBuilder {
  TodoAndThenBuilder(super.scenario);

  /// Start a fluent assertion chain for the todo list.
  TodoListAssertionBuilder todoList() => TodoListAssertionBuilder(scenario);

  /// Start a fluent assertion chain for a single todo.
  TodoAssertionBuilder todo() => TodoAssertionBuilder(scenario);

  /// Start a fluent assertion chain for notifications.
  NotificationAssertionBuilder notification() =>
      NotificationAssertionBuilder(scenario);
}
