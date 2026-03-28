/// Template for a UiDriver subclass.
///
/// Generates a feature-specific UI driver that wraps
/// WidgetTester with widget interaction methods.
String generateUiDriver({
  required String featurePascal,
  required String featureSnake,
}) {
  return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valenty_test/valenty_test.dart';

class ${featurePascal}UiDriver extends UiDriver {
  ${featurePascal}UiDriver(this.tester);

  final WidgetTester tester;

  // TODO: Add widget interaction methods
  // Example:
  // Future<void> pumpApp() async {
  //   await tester.pumpWidget(const MaterialApp(home: MyScreen()));
  //   await tester.pumpAndSettle();
  // }
  // Future<void> tapSubmit() async {
  //   await tester.tap(find.byKey(const Key('submitButton')));
  //   await tester.pumpAndSettle();
  // }
  // void verifyText(String text) => expect(find.text(text), findsOneWidget);
}
''';
}
