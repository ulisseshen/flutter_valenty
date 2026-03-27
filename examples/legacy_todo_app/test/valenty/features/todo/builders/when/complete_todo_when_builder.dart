import 'package:legacy_todo_app_example/models/todo.dart';
import 'package:legacy_todo_app_example/services/todo_service.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../setup/todo_test_environment.dart';
import '../then/todo_then_builder.dart';

/// Builder for the "complete todo" action.
///
/// Available methods:
/// - `.withTodoId(String)` — set the todo ID to complete
/// - `.then` — transition to Then phase
class CompleteTodoWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  CompleteTodoWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _todoId = '';

  /// Set the todo ID to complete.
  CompleteTodoWhenBuilder withTodoId(String id) {
    _todoId = id;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final env = ctx.get<TodoTestEnvironment>('_testEnv');

    // Configure the fake HTTP client with PATCH response from Given data
    final apiTodos = ctx.has('apiTodosResponse')
        ? ctx.get<List<Map<String, dynamic>>>('apiTodosResponse')
        : <Map<String, dynamic>>[];

    // Find the todo being completed and create a completed version
    for (final todoJson in apiTodos) {
      if (todoJson['id'] == _todoId) {
        env.fakeHttp.configurePatchResponse(_todoId, {
          ...todoJson,
          'completed': true,
        });
      }
    }

    final todoId = _todoId;
    ctx.set('_todoAction', () async {
      try {
        final todo = await TodoService.instance.completeTodo(todoId);
        return _CompleteTodoResult.success(todo);
      } catch (e) {
        return _CompleteTodoResult.failure(e.toString());
      }
    });
  }

  /// Transition to Then phase.
  TodoThenBuilder get then {
    final finalized = finalizeStep();

    final withExecution = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final action = ctx
              .get<Future<_CompleteTodoResult> Function()>('_todoAction');
          final result = await action();
          ctx.set('completeTodoResult', result);
          if (result.isSuccess) {
            ctx.set('todo', result.todo!);
            ctx.set('operationFailed', false);
          } else {
            ctx.set('operationFailed', true);
            ctx.set('operationError', result.error!);
          }
        },
      ),
    );

    final next = withExecution.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return TodoThenBuilder(next);
  }
}

class _CompleteTodoResult {
  _CompleteTodoResult.success(this.todo)
      : isSuccess = true,
        error = null;

  _CompleteTodoResult.failure(this.error)
      : isSuccess = false,
        todo = null;

  final bool isSuccess;
  final Todo? todo;
  final String? error;
}
