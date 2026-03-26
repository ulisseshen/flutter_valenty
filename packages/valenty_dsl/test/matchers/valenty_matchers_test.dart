import 'package:test/test.dart';
import 'package:valenty_dsl/src/matchers/valenty_matchers.dart';

class _Product {
  _Product({required this.name, required this.price});
  final String name;
  final double price;
}

void main() {
  group('hasField', () {
    test('matches when field equals expected value', () {
      final product = _Product(name: 'Widget', price: 9.99);
      expect(
        product,
        hasField<_Product>('name', (p) => p.name, 'Widget'),
      );
    });

    test('does not match when field differs', () {
      final product = _Product(name: 'Widget', price: 9.99);
      expect(
        product,
        isNot(hasField<_Product>('name', (p) => p.name, 'Gadget')),
      );
    });

    test('works with Matcher as expected value', () {
      final product = _Product(name: 'Widget', price: 9.99);
      expect(
        product,
        hasField<_Product>('price', (p) => p.price, greaterThan(5.0)),
      );
    });
  });

  group('satisfiesAll', () {
    test('matches when all matchers pass', () {
      expect(
        42,
        satisfiesAll([
          isA<int>(),
          greaterThan(40),
          lessThan(50),
        ]),
      );
    });

    test('does not match when any matcher fails', () {
      expect(
        42,
        isNot(
          satisfiesAll([
            isA<int>(),
            greaterThan(50),
          ]),
        ),
      );
    });
  });
}
