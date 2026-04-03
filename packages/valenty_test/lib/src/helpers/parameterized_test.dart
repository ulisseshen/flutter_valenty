import 'package:test/test.dart';

/// Run a test with multiple sets of parameters (untyped).
///
/// Example:
/// ```dart
/// parameterizedTest(
///   'addition',
///   [
///     [1, 1, 2],
///     [2, 3, 5],
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

/// A typed test case for [typedParameterizedTest].
///
/// Extend this class to create readable, type-safe test cases:
///
/// ```dart
/// class DiscountCase extends TestCase {
///   final double price;
///   final double rate;
///   final double expected;
///
///   const DiscountCase({
///     required this.price,
///     required this.rate,
///     required this.expected,
///   });
///
///   @override
///   String get label => '${rate * 100}% off \$$price = \$$expected';
/// }
/// ```
abstract class TestCase {
  const TestCase();

  /// Human-readable label for test output.
  /// Override to provide meaningful test names.
  String get label => toString();
}

/// Run a test with typed case objects — no more `params[0] as double`.
///
/// Example:
/// ```dart
/// class DiscountCase extends TestCase {
///   final double price;
///   final double rate;
///   final double expected;
///   const DiscountCase({
///     required this.price,
///     required this.rate,
///     required this.expected,
///   });
///   @override
///   String get label => '${rate * 100}% off \$$price = \$$expected';
/// }
///
/// typedParameterizedTest(
///   'calculates discount',
///   [
///     DiscountCase(price: 100, rate: 0.10, expected: 90),
///     DiscountCase(price: 100, rate: 0.25, expected: 75),
///     DiscountCase(price: 200, rate: 1.0, expected: 0),
///   ],
///   (c) {
///     expect(applyDiscount(c.price, c.rate), equals(c.expected));
///   },
/// );
/// ```
void typedParameterizedTest<T extends TestCase>(
  String name,
  List<T> cases,
  void Function(T testCase) body,
) {
  for (var i = 0; i < cases.length; i++) {
    test('$name [case ${i + 1}: ${cases[i].label}]', () => body(cases[i]));
  }
}
