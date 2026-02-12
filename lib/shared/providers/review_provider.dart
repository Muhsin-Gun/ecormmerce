import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../services/firebase_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<ReviewModel> _reviews = [];
  final Map<String, double> _averageRatingByProduct = {};
  final Map<String, int> _reviewCountByProduct = {};
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  double averageRatingFor(String productId) => _averageRatingByProduct[productId] ?? 0.0;
  int reviewCountFor(String productId) => _reviewCountByProduct[productId] ?? 0;

  Future<void> loadReviews(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firebaseService.getCollection(
        'reviews',
        queryBuilder: (q) => q.where('productId', isEqualTo: productId).orderBy('createdAt', descending: true),
      );

      _reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      _updateLocalProductRating(productId, _reviews);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(String productId, String userId, String userName, double rating, String comment) async {
    try {
      final existing = await _firebaseService.getCollection(
        'reviews',
        queryBuilder: (q) => q
            .where('productId', isEqualTo: productId)
            .where('userId', isEqualTo: userId)
            .limit(1),
      );

      if (existing.docs.isNotEmpty) {
        await _firebaseService.updateDocument('reviews', existing.docs.first.id, {
          'rating': rating,
          'review': comment.trim(),
        });
      } else {
        await _firebaseService.addDocument('reviews', {
          'productId': productId,
          'userId': userId,
          'userName': userName,
          'rating': rating,
          'review': comment.trim(),
          'verified': true,
          'helpfulCount': 0,
        });
      }

      await loadReviews(productId);
      await _recomputeAndPersistProductRating(productId);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  void _updateLocalProductRating(String productId, List<ReviewModel> productReviews) {
    if (productReviews.isEmpty) {
      _averageRatingByProduct[productId] = 0.0;
      _reviewCountByProduct[productId] = 0;
      return;
    }

    final sum = productReviews.fold<double>(0.0, (acc, r) => acc + r.rating);
    final avg = sum / productReviews.length;
    _averageRatingByProduct[productId] = double.parse(avg.toStringAsFixed(1));
    _reviewCountByProduct[productId] = productReviews.length;
  }

  Future<void> _recomputeAndPersistProductRating(String productId) async {
    final snapshot = await _firebaseService.getCollection(
      'reviews',
      queryBuilder: (q) => q.where('productId', isEqualTo: productId),
    );

    final productReviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    _updateLocalProductRating(productId, productReviews);

    final average = _averageRatingByProduct[productId] ?? 0.0;
    final count = _reviewCountByProduct[productId] ?? 0;

    await _firebaseService.updateDocument(
      'products',
      productId,
      {
        'averageRating': average,
        'reviewCount': count,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    notifyListeners();
  }
}
