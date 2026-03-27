import 'package:meta/meta.dart';

import '../models/todo.dart';
import 'http_client.dart';
import 'notification_helper.dart';
import 'storage_service.dart';

/// Singleton TodoService — typical legacy Flutter pattern.
///
/// This is the kind of code you find in real legacy apps:
/// - Singleton with hardcoded dependencies
/// - Business logic mixed with I/O
/// - No ports, no clean architecture
///
/// The ONLY production code change for testability:
/// @visibleForTesting factory lines — ONE LINE per dependency.
class TodoService {
  static final instance = TodoService._();
  TodoService._();

  // @visibleForTesting factories — ONE LINE ADDED per dependency
  @visibleForTesting
  static HttpClient Function() httpClientFactory = () => RealHttpClient();

  @visibleForTesting
  static StorageService Function() storageFactory =
      () => StorageService.instance;

  /// Fetch todos from API, with cache fallback.
  Future<List<Todo>> fetchTodos() async {
    final client = httpClientFactory();
    try {
      final todos = await client.get('/api/todos');
      final parsed =
          (todos as List).map((j) => Todo.fromJson(j as Map<String, dynamic>)).toList();

      // Cache locally
      final storage = storageFactory();
      await storage.saveTodos(parsed);

      return parsed;
    } catch (e) {
      // Fallback to cache
      final storage = storageFactory();
      return await storage.loadTodos();
    }
  }

  /// Mark a todo as completed.
  Future<Todo> completeTodo(String id) async {
    final client = httpClientFactory();
    final result =
        await client.patch('/api/todos/$id', data: {'completed': true});
    final todo = Todo.fromJson(result as Map<String, dynamic>);

    // Side effect: send notification
    NotificationHelper.send('Todo completed: ${todo.title}');

    return todo;
  }

  /// Create a new todo.
  Future<Todo> createTodo(String title) async {
    final client = httpClientFactory();
    final result = await client
        .post('/api/todos', data: {'title': title, 'completed': false});
    return Todo.fromJson(result as Map<String, dynamic>);
  }
}
