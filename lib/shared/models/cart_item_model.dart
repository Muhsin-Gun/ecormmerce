import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItemModel extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final DateTime addedAt;

  const CartItemModel({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.addedAt,
  });

  // Factory methods
  factory CartItemModel.fromProduct(ProductModel product, {int quantity = 1}) {
    return CartItemModel(
      productId: product.productId,
      name: product.name,
      quantity: quantity,
      price: product.price,
      imageUrl: product.mainImage,
      addedAt: DateTime.now(),
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      addedAt: map['addedAt'] != null 
          ? DateTime.parse(map['addedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'addedAt': addedAt.toIso8601String(),
    };
  }
  
  // CopyWith
  CartItemModel copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? imageUrl,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  // Props for Equatable
  @override
  List<Object?> get props => [productId, name, quantity, price, imageUrl, addedAt];

  // Compatibility getters for OrderModel
  String get productName => name;
  String? get productImage => imageUrl;
  double get totalPrice => price * quantity;
}
