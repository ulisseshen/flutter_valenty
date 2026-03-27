import 'package:meta/meta.dart';

import '../models/todo.dart';

/// Singleton storage service — wraps SharedPreferences-style storage.
///
/// In a real legacy Flutter app, this directly uses SharedPreferences
/// or Hive with no abstraction layer.
class StorageService {
  static final instance = StorageService._();
  StorageService._();

  final Map<String, dynamic> _cache = {};

  Future<void> saveTodos(List<Todo> todos) async {
    _cache['todos'] = todos.map((t) => t.toJson()).toList();
  }

  Future<List<Todo>> loadTodos() async {
    final data = _cache['todos'] as List?;
    if (data == null) return [];
    return data
        .map((j) => Todo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Clear cache — only used in tests.
  @visibleForTesting
  void clearForTesting() => _cache.clear();
}
