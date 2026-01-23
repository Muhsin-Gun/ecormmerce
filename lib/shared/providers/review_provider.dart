import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../models/review_model.dart';
import '../services/firebase_service.dart';

/// Provider for managing product reviews
class ReviewProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  
  // Getters
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;

  /// Load reviews for a specific product
  Future<void> loadReviews(String productId) async {
    _setLoading(true);
    try {
      final snapshot = await _firebaseService.getCollection(
        AppConstants.reviewsCollection,
        queryBuilder: (query) => query
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true),
      );

      _reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
    _setLoading(false);
  }

  /// Add a new review
  Future<bool> addReview(ReviewModel review) async {
    try {
      // 1. Add review document
      await _firebaseService.addDocument(
        AppConstants.reviewsCollection,
        review.toMap(),
      );

      // 2. Update product rating aggregation (Cloud Function usually does this, 
      // but we'll do it client-side for MVP if no functions)
      // For now, we'll assume a Cloud Function triggers the update, 
      // or we can manually update the product document here if needed.
      
      // Update local list
      _reviews.insert(0, review);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
