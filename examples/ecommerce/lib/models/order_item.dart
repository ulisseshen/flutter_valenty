import 'product.dart';

class OrderItem {
  const OrderItem({
    required this.product,
    required this.quantity,
    required this.lineTotal,
  });

  final Product product;
  final int quantity;
  final double lineTotal;
}
