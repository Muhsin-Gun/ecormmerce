import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class WishlistProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  List<ProductModel> _wishlistItems = [];
  bool _isLoading = false;
  String? _loadedUserId;

  List<ProductModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;

  Future<void> ensureLoadedForUser(String? userId) async {
    if (userId == null) {
      if (_wishlistItems.isNotEmpty || _loadedUserId != null) {
        _wishlistItems = [];
        _loadedUserId = null;
        notifyListeners();
      }
      return;
    }

    if (_loadedUserId == userId || _isLoading) return;
    await loadWishlist();
  }

  Future<void> loadWishlist() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firebaseService.getDocument('wishlists', userId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final productIds = List<String>.from(data['productIds'] ?? []);
        
        if (productIds.isNotEmpty) {
          // In a real app, you might fetch details for these IDs
          // For now, we'll assume we have a way to get them or just store IDs
          // To keep it simple, we'll fetch them from products collection
          final snapshot = await _firebaseService.getCollection(
            'products',
            queryBuilder: (q) => q.where(FieldPath.documentId, whereIn: productIds),
          );
          _wishlistItems = snapshot.docs.map((d) => ProductModel.fromFirestore(d)).toList();
        } else {
          _wishlistItems = [];
        }
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      _loadedUserId = userId;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    final isExist = _wishlistItems.any((item) => item.productId == product.productId);
    
    if (isExist) {
      _wishlistItems.removeWhere((item) => item.productId == product.productId);
    } else {
      _wishlistItems.add(product);
    }
    notifyListeners();

    try {
      await _firebaseService.setDocument('wishlists', userId, {
        'productIds': _wishlistItems.map((item) => item.productId).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing wishlist: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.productId == productId);
  }
}
