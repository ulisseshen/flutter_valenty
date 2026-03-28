import 'package:valenty_test/valenty_test.dart';

import '../when/todo_when_builder.dart';
import 'todo_given_builder.dart';

/// Builder for pre-populating cached todos in the Given phase.
///
/// Available methods:
/// - `.withTodo(id, title, completed)` — add a todo to the cache
/// - `.when` — transition to When phase
/// - `.and` — add more Given preconditions
class CachedTodosGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CachedTodosGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Map<String, dynamic>> _cachedTodos = [];

  /// Add a todo to the local cache.
  CachedTodosGivenBuilder withTodo({
    required String id,
    required String title,
    required bool completed,
  }) {
    _cachedTodos.add({
      'id': id,
      'title': title,
      'completed': completed,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final existing = ctx.has('cachedTodosData')
        ? ctx.get<List<Map<String, dynamic>>>('cachedTodosData')
        : <Map<String, dynamic>>[];

    existing.addAll(_cachedTodos);
    ctx.set('cachedTodosData', existing);
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
