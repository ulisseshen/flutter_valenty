import 'package:valenty_dsl/valenty_dsl.dart';

import 'api_todos_given_builder.dart';
import 'cached_todos_given_builder.dart';
import 'api_error_given_builder.dart';

/// GivenBuilder for the Todo feature.
///
/// Provides domain objects available in the Given phase:
/// - `.apiTodos()` — configure what the API returns
/// - `.cachedTodos()` — pre-populate the local cache
/// - `.apiError()` — configure the API to fail
class TodoGivenBuilder extends GivenBuilder {
  TodoGivenBuilder(super.scenario);

  /// Configure API todo responses.
  ApiTodosGivenBuilder apiTodos() => ApiTodosGivenBuilder(scenario);

  /// Pre-populate cached todos.
  CachedTodosGivenBuilder cachedTodos() => CachedTodosGivenBuilder(scenario);

  /// Configure the API to return an error.
  ApiErrorGivenBuilder apiError() => ApiErrorGivenBuilder(scenario);
}
