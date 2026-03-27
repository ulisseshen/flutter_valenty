/// Simple HTTP client interface — in a real app this would be Dio.
abstract class HttpClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, {Map<String, dynamic>? data});
  Future<dynamic> patch(String path, {Map<String, dynamic>? data});
}

/// Real HTTP client — in a real app this wraps Dio.
class RealHttpClient implements HttpClient {
  @override
  Future<dynamic> get(String path) async =>
      throw UnimplementedError('Use real Dio in production');

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async =>
      throw UnimplementedError('Use real Dio in production');

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async =>
      throw UnimplementedError('Use real Dio in production');
}
