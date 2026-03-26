import 'driver.dart';

/// Abstract driver for Flutter widget testing.
/// Subclass this and implement using WidgetTester from flutter_test.
abstract class FlutterWidgetDriver implements Driver {
  @override
  Future<void> setUp() async {}

  @override
  Future<void> tearDown() async {}
}
