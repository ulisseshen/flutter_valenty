class Order {
  const Order({
    required this.quantity,
    required this.basePrice,
    required this.success,
  });

  final int quantity;
  final double basePrice;
  final bool success;
}
