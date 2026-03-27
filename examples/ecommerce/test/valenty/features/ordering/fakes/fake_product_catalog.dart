import 'package:ecommerce_example/models/product.dart';
import 'package:ecommerce_example/ports/product_catalog_port.dart';

/// In-memory fake for ProductCatalogPort (replaces Firebase Firestore).
class FakeProductCatalog implements ProductCatalogPort {
  final List<Product> _products = [];

  void addProduct(Product product) {
    _products.add(product);
  }

  @override
  Future<List<Product>> getProducts() async {
    return List.unmodifiable(_products);
  }

  @override
  Future<Product> getById(String id) async {
    return _products.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Product "$id" not found in fake catalog'),
    );
  }
}
