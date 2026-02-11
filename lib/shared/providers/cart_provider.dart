import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<CartItemModel> _items = [];
  String? _couponCode;
  double _discount = 0.0;
  bool _isLoading = false;
  String? _loadedUserId;

  // Getters
  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  String? get couponCode => _couponCode;
  double get discount => _discount;
  bool get isLoading => _isLoading;

  double get discountAmount {
    if (_discount > 0) {
      if (_discount <= 1) {
         return subtotal * _discount; // Percentage
      } else {
        return _discount; // Fixed amount
      }
    }
    return 0.0;
  }

  double get total => subtotal - discountAmount;

  // Methods
  
  Future<void> ensureLoadedForUser(String? userId) async {
    if (userId == null) {
      if (_items.isNotEmpty || _loadedUserId != null) {
        _items = [];
        _loadedUserId = null;
        notifyListeners();
      }
      return;
    }

    if (_loadedUserId == userId || _isLoading) return;
    await loadCart();
  }

  Future<void> loadCart() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      _items = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      final doc = await _firebaseService.getDocument('carts', userId);

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('items')) {
            final itemsList = data['items'] as List;
            _items = itemsList.map((i) => CartItemModel.fromMap(i)).toList();
        }
        if (data.containsKey('couponCode')) _couponCode = data['couponCode'];
        if (data.containsKey('discount')) _discount = (data['discount'] ?? 0.0).toDouble();
      } else {
        _items = [];
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      _items = [];
    } finally {
      _isLoading = false;
      _loadedUserId = userId;
    }
    notifyListeners();
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((i) => i.productId == product.productId);
    
    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItemModel.fromProduct(product, quantity: quantity));
    }
    _syncCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _syncCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
        if (quantity > 0) {
           _items[index] = _items[index].copyWith(quantity: quantity);
        } else {
            _items.removeAt(index);
        }
        _syncCart();
        notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    _couponCode = null;
    _discount = 0.0;
    
    final userId = _firebaseService.currentUserId;
    if (userId != null) {
        await _firebaseService.deleteDocument('carts', userId);
    }
    notifyListeners();
  }
  
  Future<void> _syncCart() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;
    try {
        await _firebaseService.setDocument(
            'carts',
            userId,
            {
                'items': _items.map((i) => i.toMap()).toList(),
                'couponCode': _couponCode,
                'discount': _discount,
                'updatedAt': DateTime.now().toIso8601String(),
            }
        );
    } catch (e) {
        debugPrint("Error syncing cart: $e");
    }
  }

  Future<void> applyCoupon(String code) async {
     if (code.toLowerCase() == 'welcome') {
         _couponCode = code;
         _discount = 0.10;
         await _syncCart();
         notifyListeners();
     }
  }
  
  void removeCoupon() {
      _couponCode = null;
      _discount = 0.0;
      _syncCart();
      notifyListeners();
  }
}
