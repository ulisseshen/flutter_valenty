/// HTTP client interface — same as other example but with auth header injection.
abstract class HttpClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, {Map<String, dynamic>? data});
  Future<dynamic> patch(String path, {Map<String, dynamic>? data});
  Future<dynamic> delete(String path);
}

/// Production HTTP client — would use Dio/http in a real app.
class RealHttpClient implements HttpClient {
  @override
  Future<dynamic> get(String path) async => throw UnimplementedError();

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async =>
      throw UnimplementedError();

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async =>
      throw UnimplementedError();

  @override
  Future<dynamic> delete(String path) async => throw UnimplementedError();
}

/// Simple HTTP exception — mirrors what Dio would throw.
class HttpException implements Exception {
  HttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'HttpException($statusCode): $message';
}
