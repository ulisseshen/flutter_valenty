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

  group('typedParameterizedTest', () {
    typedParameterizedTest(
      'calculates area',
      [
        _AreaCase(width: 10, height: 5, expected: 50),
        _AreaCase(width: 3, height: 7, expected: 21),
        _AreaCase(width: 0, height: 100, expected: 0),
      ],
      (c) {
        expect(c.width * c.height, equals(c.expected));
      },
    );

    typedParameterizedTest(
      'formats greeting',
      [
        _GreetingCase(name: 'Alice', expected: 'Hello, Alice!'),
        _GreetingCase(name: 'Bob', expected: 'Hello, Bob!'),
      ],
      (c) {
        expect('Hello, ${c.name}!', equals(c.expected));
      },
    );
  });
}

class _AreaCase extends TestCase {
  final int width;
  final int height;
  final int expected;
  const _AreaCase({
    required this.width,
    required this.height,
    required this.expected,
  });
  @override
  String get label => '${width}x$height = $expected';
}

class _GreetingCase extends TestCase {
  final String name;
  final String expected;
  const _GreetingCase({required this.name, required this.expected});
  @override
  String get label => name;
}
