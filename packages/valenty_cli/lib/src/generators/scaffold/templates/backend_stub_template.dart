/// Template for a BackendStubDsl subclass.
///
/// Generates a feature-specific backend stub that overrides
/// singleton factories with fakes using @visibleForTesting.
String generateBackendStub({
  required String featurePascal,
  required String featureSnake,
}) {
  return '''
import 'package:valenty_test/valenty_test.dart';

class ${featurePascal}BackendStub extends BackendStubDsl {
  // TODO: Add fake data fields
  // Example:
  // final List<Item> _items = [];
  // void stubItems(List<Item> items) => _items.addAll(items);

  @override
  Future<void> apply() async {
    // TODO: Override singleton factories with fakes
    // Example:
    // ItemService.fetchItemsOverride = () async => List.of(_items);
  }

  @override
  Future<void> restore() async {
    // TODO: Reset singleton factories
    // Example:
    // ItemService.resetForTesting();
  }
}
''';
}
