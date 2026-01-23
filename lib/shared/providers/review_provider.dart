import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/firebase_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> loadReviews(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firebaseService.getCollection(
        'reviews',
        queryBuilder: (q) => q.where('productId', isEqualTo: productId).orderBy('createdAt', descending: true),
      );

      _reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(String productId, String userId, String userName, double rating, String comment) async {
    try {
      await _firebaseService.addDocument('reviews', {
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Refresh reviews
      await loadReviews(productId);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }
}
