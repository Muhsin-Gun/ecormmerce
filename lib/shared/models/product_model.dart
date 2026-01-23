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
  
  String get mainImage => imageUrl ?? (images.isNotEmpty ? images.first : '') ?? '';

  int get stockQuantity => stock;

  double? get compareAtPrice => isOnSale ? price : null;

  // Factory for Firestore
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? (data['images'] != null && (data['images'] as List).isNotEmpty ? data['images'][0] : null),
      brand: data['brand'],
      isOnSale: data['isOnSale'] ?? false,
      salePrice: data['salePrice']?.toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrl': imageUrl,
      'brand': brand,
      'isOnSale': isOnSale,
      'salePrice': salePrice,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'images': images,
    };
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
  List<Object?> get props => [productId, name, description, price, stock, category, imageUrl, createdAt, updatedAt];
}
