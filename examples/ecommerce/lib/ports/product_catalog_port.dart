import '../models/product.dart';

/// Port for accessing the product catalog (backed by Firebase Firestore).
abstract class ProductCatalogPort {
  Future<List<Product>> getProducts();
  Future<Product> getById(String id);
}
