import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/test_context.dart';

void main() {
  late TestContext ctx;

  setUp(() {
    ctx = TestContext();
  });

  group('TestContext', () {
    test('stores and retrieves a value by key', () {
      ctx.set('name', 'Alice');
      expect(ctx.get<String>('name'), 'Alice');
    });

    test('stores and retrieves typed values', () {
      ctx.set('count', 42);
      ctx.set('active', true);
      ctx.set('ratio', 3.14);

      expect(ctx.get<int>('count'), 42);
      expect(ctx.get<bool>('active'), true);
      expect(ctx.get<double>('ratio'), 3.14);
    });

    test('has returns true for existing keys', () {
      ctx.set('key', 'value');
      expect(ctx.has('key'), isTrue);
    });

    test('has returns false for missing keys', () {
      expect(ctx.has('missing'), isFalse);
    });

    test('clear removes all values', () {
      ctx.set('a', 1);
      ctx.set('b', 2);
      ctx.clear();

      expect(ctx.has('a'), isFalse);
      expect(ctx.has('b'), isFalse);
    });

    test('throws StateError for missing key', () {
      expect(
        () => ctx.get<String>('missing'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError for wrong type', () {
      ctx.set('count', 42);
      expect(
        () => ctx.get<String>('count'),
        throwsA(isA<StateError>()),
      );
    });

    test('overwrites existing value with same key', () {
      ctx.set('name', 'Alice');
      ctx.set('name', 'Bob');
      expect(ctx.get<String>('name'), 'Bob');
    });
  });
}
