import 'driver.dart';

/// Abstract driver for HTTP-based testing.
abstract class HttpDriver implements Driver {
  HttpDriver({required this.baseUrl});
  final String baseUrl;

  @override
  Future<void> setUp() async {}

  @override
  Future<void> tearDown() async {}
}
