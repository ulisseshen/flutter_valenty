/// Template for a SystemDsl subclass.
///
/// Generates a feature-specific system DSL that delegates
/// user actions to the UI driver using domain language.
String generateSystemDsl({
  required String featurePascal,
  required String featureSnake,
}) {
  return '''
import 'package:valenty_dsl/valenty_dsl.dart';

import '${featureSnake}_ui_driver.dart';

class ${featurePascal}SystemDsl extends SystemDsl {
  ${featurePascal}SystemDsl(this.driver);

  final ${featurePascal}UiDriver driver;

  // TODO: Add domain-language user actions
  // Example:
  // Future<void> openApp() async => driver.pumpApp();
  // Future<void> addItem({required String name}) async {
  //   await driver.enterName(name);
  //   await driver.tapSubmit();
  // }
  // void verifyItemVisible(String name) => driver.verifyText(name);
}
''';
}
