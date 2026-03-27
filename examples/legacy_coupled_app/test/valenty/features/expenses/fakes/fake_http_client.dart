import 'package:legacy_coupled_app_example/services/http_client.dart';

/// Configurable fake HTTP client for testing.
///
/// Supports GET, POST, PATCH, DELETE with configurable responses per path.
/// Multiple response configurations can be set for different API paths
/// (e.g., /api/expenses, /api/auth/login).
class FakeHttpClient implements HttpClient {
  /// Responses for GET requests, keyed by path prefix.
  final Map<String, dynamic> _getResponses = {};

  /// Error code to throw on GET requests for specific paths (null = no error).
  final Map<String, int> _getErrors = {};

  /// Responses for POST requests, keyed by path.
  final Map<String, dynamic Function(Map<String, dynamic>? data)>
      _postHandlers = {};

  /// Responses for PATCH requests, keyed by path.
  final Map<String, dynamic Function(Map<String, dynamic>? data)>
      _patchHandlers = {};

  /// Responses for DELETE requests, keyed by path.
  final Map<String, dynamic Function()> _deleteHandlers = {};

  /// Configure what a GET request to [path] returns.
  void configureGet(String path, dynamic response) {
    _getResponses[path] = response;
  }

  /// Configure a GET request to [path] to fail with [statusCode].
  void configureGetError(String path, int statusCode) {
    _getErrors[path] = statusCode;
  }

  /// Configure what a POST request to [path] returns.
  void configurePost(
    String path,
    dynamic Function(Map<String, dynamic>? data) handler,
  ) {
    _postHandlers[path] = handler;
  }

  /// Configure what a PATCH request to [path] returns.
  void configurePatch(
    String path,
    dynamic Function(Map<String, dynamic>? data) handler,
  ) {
    _patchHandlers[path] = handler;
  }

  /// Configure what a DELETE request to [path] returns.
  void configureDelete(String path, dynamic Function() handler) {
    _deleteHandlers[path] = handler;
  }

  @override
  Future<dynamic> get(String path) async {
    // Check for error first (match by prefix)
    for (final entry in _getErrors.entries) {
      if (path.startsWith(entry.key)) {
        throw HttpException(entry.value, 'Server error');
      }
    }

    // Check for configured response (match by prefix)
    for (final entry in _getResponses.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value;
      }
    }

    throw HttpException(404, 'Not found: $path');
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    final handler = _postHandlers[path];
    if (handler != null) {
      return handler(data);
    }

    throw HttpException(404, 'Not found: $path');
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async {
    final handler = _patchHandlers[path];
    if (handler != null) {
      return handler(data);
    }

    throw HttpException(404, 'Not found: $path');
  }

  @override
  Future<dynamic> delete(String path) async {
    final handler = _deleteHandlers[path];
    if (handler != null) {
      return handler();
    }

    throw HttpException(404, 'Not found: $path');
  }
}
