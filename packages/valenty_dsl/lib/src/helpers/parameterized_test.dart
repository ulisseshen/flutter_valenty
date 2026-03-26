import 'package:test/test.dart';

/// Run a test with multiple sets of parameters.
///
/// Example:
/// ```dart
/// parameterizedTest(
///   'addition',
///   [
///     [1, 1, 2],
///     [2, 3, 5],
///     [0, 0, 0],
///   ],
///   (List<dynamic> params) {
///     final a = params[0] as int;
///     final b = params[1] as int;
///     final expected = params[2] as int;
///     expect(a + b, equals(expected));
///   },
/// );
/// ```
void parameterizedTest(
  String name,
  List<List<dynamic>> cases,
  void Function(List<dynamic> params) body,
) {
  for (var i = 0; i < cases.length; i++) {
    test('$name [case ${i + 1}: ${cases[i]}]', () => body(cases[i]));
  }
}
