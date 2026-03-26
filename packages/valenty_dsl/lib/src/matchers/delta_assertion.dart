import 'package:test/test.dart';

/// Assert that an expression changes from one value to another
/// after an action is performed.
///
/// Example:
/// ```dart
/// await expectDelta(
///   () => repository.count(),
///   action: () => repository.add(item),
///   from: 0,
///   to: 1,
/// );
/// ```
Future<void> expectDelta<T>(
  T Function() expression, {
  required Future<void> Function() action,
  required T from,
  required T to,
}) async {
  expect(expression(), equals(from), reason: 'Before action');
  await action();
  expect(expression(), equals(to), reason: 'After action');
}
