import 'package:valenty_test/valenty_test.dart';

import '../when/todo_when_builder.dart';
import 'todo_given_builder.dart';

/// Builder for configuring API todo responses in the Given phase.
///
/// Available methods:
/// - `.withTodo(id, title, completed)` — add a todo to the API response
/// - `.withTodos(List)` — add multiple todos at once
/// - `.withCreateEnabled()` — enable POST /api/todos
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class ApiTodosGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ApiTodosGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Map<String, dynamic>> _todos = [];
  bool _createEnabled = false;

  /// Add a single todo to the API response.
  ApiTodosGivenBuilder withTodo({
    required String id,
    required String title,
    required bool completed,
  }) {
    _todos.add({
      'id': id,
      'title': title,
      'completed': completed,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return this;
  }

  /// Add multiple todos at once.
  ApiTodosGivenBuilder withTodos(List<Map<String, dynamic>> todos) {
    _todos.addAll(todos);
    return this;
  }

  /// Enable POST /api/todos (for create scenarios).
  ApiTodosGivenBuilder withCreateEnabled() {
    _createEnabled = true;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // Store API response data
    final existing = ctx.has('apiTodosResponse')
        ? ctx.get<List<Map<String, dynamic>>>('apiTodosResponse')
        : <Map<String, dynamic>>[];

    existing.addAll(_todos);
    ctx.set('apiTodosResponse', existing);

    if (_createEnabled) {
      ctx.set('apiCreateEnabled', true);
    }
  }

  /// Transition to When phase.
  TodoWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return TodoWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  TodoGivenBuilder get and {
    final finalized = finalizeStep();
    return TodoGivenBuilder(finalized);
  }
}
