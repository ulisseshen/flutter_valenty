import 'order_item.dart';

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.totalPrice,
    this.taxAmount = 0,
    required this.status,
  });

  final String id;
  final List<OrderItem> items;
  final double totalPrice;
  final double taxAmount;
  final String status;
}
