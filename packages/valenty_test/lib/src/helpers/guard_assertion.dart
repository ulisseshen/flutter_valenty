import 'package:test/test.dart';

/// Helper for testing guard clauses (precondition checks).
///
/// Example:
/// ```dart
/// guardAssertion(
///   () => MyClass(name: ''),
///   throwsA(isA<ArgumentError>()),
/// );
/// ```
void guardAssertion(
  dynamic Function() action,
  Matcher matcher,
) {
  expect(action, matcher);
}
