/// Template for the valentyTest helper function.
///
/// Generates a feature-specific `valentyTest()` wrapper that
/// creates the backend stub, UI driver, and system DSL.
String generateValentyTestHelper({
  required String featurePascal,
  required String featureSnake,
}) {
  return '''
import 'package:flutter_test/flutter_test.dart';

import 'dsl/${featureSnake}_backend_stub.dart';
import 'dsl/${featureSnake}_system_dsl.dart';
import 'dsl/${featureSnake}_ui_driver.dart';

/// valentyTest wrapper for the $featurePascal feature.
///
/// Sets up the full app with faked backend for UI-first component testing.
void valentyTest(
  String description, {
  void Function(${featurePascal}BackendStub backend)? setup,
  required Future<void> Function(
    ${featurePascal}SystemDsl system,
    ${featurePascal}BackendStub backend,
  ) body,
}) {
  testWidgets(description, (tester) async {
    final backend = ${featurePascal}BackendStub();
    if (setup != null) setup(backend);
    await backend.apply();
    try {
      final driver = ${featurePascal}UiDriver(tester);
      final system = ${featurePascal}SystemDsl(driver);
      await body(system, backend);
    } finally {
      await backend.restore();
    }
  });
}
''';
}
