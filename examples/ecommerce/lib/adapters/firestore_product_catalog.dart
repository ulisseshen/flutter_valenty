import '../models/product.dart';
import '../ports/product_catalog_port.dart';

/// Adapter that implements [ProductCatalogPort] using Firebase Cloud Firestore.
///
/// In a real Flutter project, this class would depend on the `cloud_firestore`
/// package and interact with a Firestore collection. Since this is a pure Dart
/// example (no Flutter SDK), we provide an in-memory implementation that
/// demonstrates the pattern.
///
/// ## Real Flutter implementation sketch
///
/// ```dart
/// import 'package:cloud_firestore/cloud_firestore.dart';
///
/// class FirestoreProductCatalog implements ProductCatalogPort {
///   final FirebaseFirestore _firestore;
///
///   FirestoreProductCatalog({FirebaseFirestore? firestore})
///       : _firestore = firestore ?? FirebaseFirestore.instance;
///
///   CollectionReference<Map<String, dynamic>> get _collection =>
///       _firestore.collection('products');
///
///   @override
///   Future<List<Product>> getProducts() async {
///     final snapshot = await _collection.get();
///     return snapshot.docs.map(_fromDocument).toList();
///   }
///
///   @override
///   Future<Product> getById(String id) async {
///     final doc = await _collection.doc(id).get();
///     if (!doc.exists) throw Exception('Product not found: $id');
///     return _fromDocument(doc);
///   }
///
///   Product _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
///     final data = doc.data();
///     return Product(
///       id: doc.id,
///       name: data['name'] as String,
///       unitPrice: (data['unitPrice'] as num).toDouble(),
///       sku: (data['sku'] as String?) ?? '',
///     );
///   }
/// }
/// ```
class FirestoreProductCatalog implements ProductCatalogPort {
  /// Creates a [FirestoreProductCatalog] with optional seed data.
  ///
  /// In a real implementation, the constructor would receive a
  /// `FirebaseFirestore` instance (or use `FirebaseFirestore.instance`).
  FirestoreProductCatalog({List<Product>? initialProducts})
      : _products = {
          for (final p in initialProducts ?? <Product>[]) p.id: p,
        };

  /// Simulates the Firestore 'products' collection as an in-memory map.
  /// Key = document ID, Value = Product.
  final Map<String, Product> _products;

  @override
  Future<List<Product>> getProducts() async {
    // In real Firestore: _collection.get() -> snapshot.docs.map(...)
    return _products.values.toList();
  }

  @override
  Future<Product> getById(String id) async {
    // In real Firestore: _collection.doc(id).get()
    final product = _products[id];
    if (product == null) {
      throw ProductNotFoundException('Product not found: $id');
    }
    return product;
  }
}

/// Exception thrown when a product document does not exist in Firestore.
class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'ProductNotFoundException: $message';
}
