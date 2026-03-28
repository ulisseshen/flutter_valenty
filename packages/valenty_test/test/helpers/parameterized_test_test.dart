import 'package:test/test.dart';
import 'package:valenty_test/src/helpers/parameterized_test.dart';

void main() {
  group('parameterizedTest', () {
    parameterizedTest(
      'addition works correctly',
      [
        [1, 1, 2],
        [2, 3, 5],
        [0, 0, 0],
        [-1, 1, 0],
      ],
      (params) {
        final a = params[0] as int;
        final b = params[1] as int;
        final expected = params[2] as int;
        expect(a + b, equals(expected));
      },
    );

    parameterizedTest(
      'string length',
      [
        ['', 0],
        ['a', 1],
        ['hello', 5],
      ],
      (params) {
        final input = params[0] as String;
        final expected = params[1] as int;
        expect(input.length, equals(expected));
      },
    );
  });
}
