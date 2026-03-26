import 'package:test/test.dart';
import 'package:valenty_dsl/src/helpers/guard_assertion.dart';

void main() {
  group('guardAssertion', () {
    test('passes when action throws expected exception', () {
      guardAssertion(
        () => throw ArgumentError('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('passes when action throws with specific message', () {
      guardAssertion(
        () => throw FormatException('bad format'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'bad format',
          ),
        ),
      );
    });
  });
}
