class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.sku = '',
  });

  final String id;
  final String name;
  final double unitPrice;
  final String sku;
}
