import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../services/firebase_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<ReviewModel> _reviews = [];
  final Map<String, double> _averageRatingByProduct = {};
  final Map<String, int> _reviewCountByProduct = {};
  final Set<String> _pendingReviewKeys = {};
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  double averageRatingFor(String productId) => _averageRatingByProduct[productId] ?? 0.0;
  int reviewCountFor(String productId) => _reviewCountByProduct[productId] ?? 0;
  bool isSubmitting(String productId, String userId) =>
      _pendingReviewKeys.contains(_reviewKey(productId, userId));

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
    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      throw Exception('Please write a review before submitting.');
    }

    final pendingKey = _reviewKey(productId, userId);
    if (_pendingReviewKeys.contains(pendingKey)) {
      return;
    }

    _pendingReviewKeys.add(pendingKey);
    final previousReviews = List<ReviewModel>.from(_reviews);
    final now = DateTime.now();
    final optimisticReview = ReviewModel(
      reviewId: 'local_${productId}_$userId',
      productId: productId,
      userId: userId,
      userName: userName,
      rating: rating,
      review: trimmedComment,
      verified: true,
      helpfulCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    final existingIndex = _reviews.indexWhere(
      (review) => review.productId == productId && review.userId == userId,
    );
    if (existingIndex >= 0) {
      _reviews[existingIndex] = optimisticReview;
    } else {
      _reviews = [optimisticReview, ..._reviews];
    }
    _updateLocalProductRating(productId, _reviews);
    notifyListeners();

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
          'review': trimmedComment,
        });
      } else {
        await _firebaseService.addDocument('reviews', {
          'productId': productId,
          'userId': userId,
          'userName': userName,
          'rating': rating,
          'review': trimmedComment,
          'verified': true,
          'helpfulCount': 0,
        });
      }

      unawaited(_refreshReviewsSilently(productId));
      unawaited(_recomputeAndPersistProductRating(productId));
    } catch (e) {
      _reviews = previousReviews;
      _updateLocalProductRating(productId, _reviews);
      notifyListeners();
      debugPrint('Error adding review: $e');
      rethrow;
    } finally {
      _pendingReviewKeys.remove(pendingKey);
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

  Future<void> _refreshReviewsSilently(String productId) async {
    try {
      final snapshot = await _firebaseService.getCollection(
        'reviews',
        queryBuilder: (q) => q
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true),
      );
      _reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
      _updateLocalProductRating(productId, _reviews);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing reviews: $e');
    }
  }

  String _reviewKey(String productId, String userId) => '$productId::$userId';
}
