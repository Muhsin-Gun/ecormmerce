import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../models/product_model.dart';
import 'firebase_service.dart';

class ProductService {
  final FirebaseService _firebaseService = FirebaseService.instance;

  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  /// Get paginated products
  Future<QuerySnapshot> getProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    bool descending = true,
  }) async {
    return _firebaseService.getPaginatedDocuments(
      AppConstants.productsCollection,
      limit: limit,
      startAfter: startAfter,
      queryBuilder: (query) {
        var q = query.where('isActive', isEqualTo: true);
        if (category != null) {
          q = q.where('category', isEqualTo: category);
        }
        return q.orderBy('createdAt', descending: descending);
      },
    );
  }

  /// Get featured products
  Future<QuerySnapshot> getFeaturedProducts({int limit = 10}) async {
    return _firebaseService.getCollection(
      AppConstants.productsCollection,
      queryBuilder: (query) {
        return query
            .where('isActive', isEqualTo: true)
            .where('isFeatured', isEqualTo: true)
            .limit(limit);
      },
    );
  }

  /// Get related products
  Future<List<ProductModel>> getRelatedProducts(String category, String excludeId, {int limit = 4}) async {
    final snapshot = await _firebaseService.getCollection(
      AppConstants.productsCollection,
      queryBuilder: (query) {
        return query
            .where('isActive', isEqualTo: true)
            .where('category', isEqualTo: category)
            .limit(limit + 1);
      },
    );

    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => p.productId != excludeId)
        .take(limit)
        .toList();
  }

  /// Get single product
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firebaseService.getDocument(
      AppConstants.productsCollection,
      productId,
    );
    if (doc.exists) {
      return ProductModel.fromFirestore(doc);
    }
    return null;
  }

  /// Add product
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _firebaseService.addDocument(AppConstants.productsCollection, data);
  }

  /// Update product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firebaseService.updateDocument(AppConstants.productsCollection, productId, data);
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    await _firebaseService.updateDocument(AppConstants.productsCollection, productId, {'isActive': false});
  }

  /// Update stock
  Future<void> updateStock(String productId, int newStock) async {
    await _firebaseService.updateDocument(AppConstants.productsCollection, productId, {'stock': newStock});
  }
}
