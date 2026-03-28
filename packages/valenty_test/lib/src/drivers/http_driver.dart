import 'driver.dart';

/// Abstract driver for HTTP-based testing.
abstract class HttpDriver implements Driver {
  /// Create an HTTP driver targeting the given [baseUrl].
  HttpDriver({required this.baseUrl});

  /// The base URL for HTTP requests.
  final String baseUrl;

  @override
  Future<void> setUp() async {}

  @override
  Future<void> tearDown() async {}
}
