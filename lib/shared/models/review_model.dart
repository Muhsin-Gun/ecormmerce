import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Product review model
class ReviewModel extends Equatable {
  final String reviewId;
  final String productId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final double rating;
  final String review;
  final List<String>? images;
  final bool verified; // Verified purchase
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.rating,
    required this.review,
    this.images,
    this.verified = false,
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReviewModel(
      reviewId: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'],
      rating: (data['rating'] ?? 0).toDouble(),
      review: data['review'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      verified: data['verified'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImage: map['userProfileImage'],
      rating: (map['rating'] ?? 0).toDouble(),
      review: map['review'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      verified: map['verified'] ?? false,
      helpfulCount: map['helpfulCount'] ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // ==================== TO MAP ====================

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'rating': rating,
      'review': review,
      'images': images,
      'verified': verified,
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ==================== COPY WITH ====================

  ReviewModel copyWith({
    String? reviewId,
    String? productId,
    String? userId,
    String? userName,
    String? userProfileImage,
    double? rating,
    String? review,
    List<String>? images,
    bool? verified,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      images: images ?? this.images,
      verified: verified ?? this.verified,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== EQUATABLE ====================

  @override
  List<Object?> get props => [
        reviewId,
        productId,
        userId,
        userName,
        userProfileImage,
        rating,
        review,
        images,
        verified,
        helpfulCount,
        createdAt,
        updatedAt,
      ];
      
  // UI Aliases
  String get comment => review;
  String? get userImage => userProfileImage;
}
