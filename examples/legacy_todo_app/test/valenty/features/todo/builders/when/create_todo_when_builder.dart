import 'package:legacy_todo_app_example/models/todo.dart';
import 'package:legacy_todo_app_example/services/todo_service.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

import '../../setup/todo_test_environment.dart';
import '../then/todo_then_builder.dart';

/// Builder for the "create todo" action.
///
/// Available methods:
/// - `.withTitle(String)` — set the title of the new todo
/// - `.then` — transition to Then phase
class CreateTodoWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  CreateTodoWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  String _title = '';

  /// Set the title for the new todo.
  CreateTodoWhenBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final env = ctx.get<TodoTestEnvironment>('_testEnv');

    // Enable POST on the fake client if Given specified createEnabled
    final createEnabled = ctx.has('apiCreateEnabled')
        ? ctx.get<bool>('apiCreateEnabled')
        : false;

    if (createEnabled) {
      env.fakeHttp.enableCreate();
    }

    final title = _title;
    ctx.set('_todoAction', () async {
      try {
        final todo = await TodoService.instance.createTodo(title);
        return _CreateTodoResult.success(todo);
      } catch (e) {
        return _CreateTodoResult.failure(e.toString());
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
              .get<Future<_CreateTodoResult> Function()>('_todoAction');
          final result = await action();
          ctx.set('createTodoResult', result);
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

class _CreateTodoResult {
  _CreateTodoResult.success(this.todo)
      : isSuccess = true,
        error = null;

  _CreateTodoResult.failure(this.error)
      : isSuccess = false,
        todo = null;

  final bool isSuccess;
  final Todo? todo;
  final String? error;
}
