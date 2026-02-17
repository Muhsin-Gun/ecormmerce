import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String productId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String? imageUrl;
  final String? brand;

  // Optional sale fields
  final bool isOnSale;
  final double? salePrice;

  // Extra fields to prevent breakage if other files use them (e.g. fromFirestore might need them)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double averageRating;
  final int reviewCount;
  final List<String> images;

  const ProductModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl,
    this.brand,
    this.isOnSale = false,
    this.salePrice,
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.images = const [],
  }) : updatedAt = updatedAt ?? createdAt;

  /// 🔁 Compatibility getters (DO NOT REMOVE)
  String get id => productId;

  bool get inStock => stock > 0;

  bool get lowStock => stock > 0 && stock <= 5;

  double? get discountPercentage {
    if (!isOnSale || salePrice == null || salePrice! >= price) return null;
    return ((price - salePrice!) / price) * 100;
  }

  String get mainImage => imageUrl ?? (images.isNotEmpty ? images.first : '');

  int get stockQuantity => stock;

  double? get compareAtPrice => isOnSale ? price : null;

  // Factory for Firestore
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Handle null timestamps
    DateTime getTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // Safely get list
    List<String> getImages(dynamic images) {
      if (images == null) return [];
      if (images is List) return images.map((e) => e.toString()).toList();
      return [];
    }

    return ProductModel(
      productId: doc.id,
      name: data['name']?.toString() ?? 'Unknown Product',
      description: data['description']?.toString() ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      stock: (data['stock'] is int) ? data['stock'] as int : 0,
      category: data['category']?.toString() ?? 'Uncategorized',
      imageUrl: data['imageUrl']?.toString() ??
          (data['images'] != null && (data['images'] as List).isNotEmpty
              ? data['images'][0]?.toString()
              : null),
      brand: data['brand']?.toString(),
      isOnSale: data['isOnSale'] == true,
      salePrice: (data['salePrice'] is num)
          ? (data['salePrice'] as num).toDouble()
          : null,
      isActive: data['isActive'] != false, // Default to true if missing
      createdAt: getTimestamp(data['createdAt']),
      updatedAt: getTimestamp(data['updatedAt']),
      averageRating: (data['averageRating'] is num)
          ? (data['averageRating'] as num).toDouble()
          : 0.0,
      reviewCount:
          (data['reviewCount'] is int) ? data['reviewCount'] as int : 0,
      images: getImages(data['images']),
    );
  }

  // toMap
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'isOnSale': isOnSale,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'images': images,
    };

    final normalizedImage = imageUrl?.trim();
    if (normalizedImage != null && normalizedImage.isNotEmpty) {
      map['imageUrl'] = normalizedImage;
    }

    final normalizedBrand = brand?.trim();
    if (normalizedBrand != null && normalizedBrand.isNotEmpty) {
      map['brand'] = normalizedBrand;
    }

    if (salePrice != null) {
      map['salePrice'] = salePrice;
    }

    return map;
  }

  ProductModel copyWith({
    String? productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    String? brand,
    bool? isOnSale,
    double? salePrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? averageRating,
    int? reviewCount,
    List<String>? images,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      isOnSale: isOnSale ?? this.isOnSale,
      salePrice: salePrice ?? this.salePrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        description,
        price,
        stock,
        category,
        imageUrl,
        createdAt,
        updatedAt
      ];
}
