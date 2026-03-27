import 'package:legacy_todo_app_example/services/http_client.dart';

/// Configurable fake HTTP client for testing.
///
/// Replaces RealHttpClient (which wraps Dio in production) with
/// pre-configured responses for each endpoint.
class FakeHttpClient implements HttpClient {
  /// Responses for GET /api/todos.
  List<Map<String, dynamic>>? _getTodosResponse;

  /// Error code to throw on GET requests (null = no error).
  int? _getErrorCode;

  /// Responses for PATCH /api/todos/:id.
  final Map<String, Map<String, dynamic>> _patchResponses = {};

  /// Whether POST /api/todos is enabled.
  bool _createEnabled = false;

  /// Next ID for created todos.
  int _nextId = 100;

  /// Configure what GET /api/todos returns.
  void configureTodos(List<Map<String, dynamic>> todos) {
    _getTodosResponse = todos;
  }

  /// Configure GET requests to fail with a status code.
  void configureGetError(int statusCode) {
    _getErrorCode = statusCode;
  }

  /// Configure a PATCH response for a specific todo ID.
  void configurePatchResponse(String id, Map<String, dynamic> response) {
    _patchResponses[id] = response;
  }

  /// Enable POST /api/todos.
  void enableCreate() {
    _createEnabled = true;
  }

  @override
  Future<dynamic> get(String path) async {
    if (_getErrorCode != null) {
      throw HttpException(_getErrorCode!, 'Server error');
    }

    if (path == '/api/todos' && _getTodosResponse != null) {
      return _getTodosResponse!;
    }

    throw HttpException(404, 'Not found: $path');
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    if (path == '/api/todos' && _createEnabled && data != null) {
      final id = '${_nextId++}';
      return {
        'id': id,
        'title': data['title'] as String,
        'completed': data['completed'] as bool? ?? false,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    throw HttpException(404, 'Not found: $path');
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async {
    // Extract ID from /api/todos/:id
    final match = RegExp(r'/api/todos/(.+)').firstMatch(path);
    if (match != null) {
      final id = match.group(1)!;
      if (_patchResponses.containsKey(id)) {
        return _patchResponses[id]!;
      }
    }

    throw HttpException(404, 'Not found: $path');
  }
}

/// Simple HTTP exception — mirrors what Dio would throw.
class HttpException implements Exception {
  HttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'HttpException($statusCode): $message';
}
