import 'package:legacy_todo_app_example/models/todo.dart';
import 'package:legacy_todo_app_example/services/storage_service.dart';
import 'package:legacy_todo_app_example/services/todo_service.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../setup/todo_test_environment.dart';
import '../then/todo_then_builder.dart';

/// Builder for the "fetch todos" action.
///
/// No additional configuration needed — just `.then` to transition.
class FetchTodosWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  FetchTodosWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  @override
  void applyToContext(TestContext ctx) {
    // Build fakes from Given-phase context
    final env = ctx.get<TodoTestEnvironment>('_testEnv');

    // Configure the fake HTTP client from context
    final hasError =
        ctx.has('apiHasError') ? ctx.get<bool>('apiHasError') : false;

    if (hasError) {
      final errorCode = ctx.get<int>('apiErrorCode');
      env.fakeHttp.configureGetError(errorCode);
    } else {
      final apiTodos = ctx.has('apiTodosResponse')
          ? ctx.get<List<Map<String, dynamic>>>('apiTodosResponse')
          : <Map<String, dynamic>>[];
      env.fakeHttp.configureTodos(apiTodos);
    }

    // Pre-populate cache if needed
    final cachedTodos = ctx.has('cachedTodosData')
        ? ctx.get<List<Map<String, dynamic>>>('cachedTodosData')
        : <Map<String, dynamic>>[];

    if (cachedTodos.isNotEmpty) {
      final todos = cachedTodos
          .map((j) => Todo.fromJson(j))
          .toList();
      // Synchronously seed the cache
      StorageService.instance.saveTodos(todos);
    }

    // Store the action to execute
    ctx.set('_todoAction', () async {
      try {
        final todos = await TodoService.instance.fetchTodos();
        return _TodoResult.successList(todos);
      } catch (e) {
        return _TodoResult.failure(e.toString());
      }
    });
  }

  /// Transition to Then phase.
  TodoThenBuilder get then {
    final finalized = finalizeStep();

    // Add execution step that runs the async action
    final withExecution = finalized.appendStep(
      StepRecord(
        phase: StepPhase.when,
        action: (ctx) async {
          final action =
              ctx.get<Future<_TodoResult> Function()>('_todoAction');
          final result = await action();
          ctx.set('todoResult', result);
          if (result.isSuccess) {
            ctx.set('todoList', result.todos!);
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

/// Internal result wrapper for async todo operations.
class _TodoResult {
  _TodoResult.successList(this.todos)
      : isSuccess = true,
        error = null;

  _TodoResult.failure(this.error)
      : isSuccess = false,
        todos = null;

  final bool isSuccess;
  final List<Todo>? todos;
  final String? error;
}
