import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// Product Provider for managing product catalog and inventory
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _relatedProducts = [];
  List<String> _recentlyViewedIds = [];
  Set<String> _recentlyViewedIdsSet = {};
  ProductModel? _selectedProduct;

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  String? _selectedCategory;
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _currentSortBy = 'newest';

  // ==================== GETTERS ====================

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get relatedProducts => _relatedProducts;
  List<ProductModel> get recentlyViewedProducts =>
      _products.where((p) => _recentlyViewedIdsSet.contains(p.productId)).toList();
  ProductModel? get selectedProduct => _selectedProduct;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  String get currentSortBy => _currentSortBy;

  int get productCount => _filteredProducts.length;

  // ==================== LOAD PRODUCTS ====================

  /// Load initial products
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _products.clear();
      _filteredProducts.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    _setLoading(true);

    try {
      final snapshot = await _productService.getProducts(
        limit: AppConstants.productsPerPage,
        startAfter: refresh ? null : _lastDocument,
        category: _selectedCategory,
      );

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;

        final newProducts = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();

        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        if (snapshot.docs.length < AppConstants.productsPerPage) {
          _hasMore = false;
        }

        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _setLoading(false);
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadProducts();
  }

  /// Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      final snapshot = await _productService.getFeaturedProducts(limit: 10);

      _featuredProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured products: $e');
    }
  }

  /// Load products by category
  Future<void> loadProductsByCategory(String category) async {
    _setLoading(true);

    try {
      final snapshot = await _productService.getProducts(
        category: category,
        limit: 50, // More for category view
      );

      _products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading products by category: $e');
    }

    _setLoading(false);
  }

  /// Load related products
  Future<void> loadRelatedProducts(String category, String excludeId) async {
    try {
      _relatedProducts = await _productService.getRelatedProducts(category, excludeId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading related products: $e');
    }
  }

  void addToRecentlyViewed(String productId) {
    if (!_recentlyViewedIds.contains(productId)) {
      _recentlyViewedIds.insert(0, productId);
      if (_recentlyViewedIds.length > 10) {
        _recentlyViewedIds.removeLast();
      }
      _recentlyViewedIdsSet = _recentlyViewedIds.toSet();
      notifyListeners();
    }
  }

  // ==================== SINGLE PRODUCT ====================

  /// Load single product by ID
  Future<void> loadProduct(String productId) async {
    try {
      _selectedProduct = await _productService.getProduct(productId);
    } catch (e) {
      debugPrint('Error loading product: $e');
    }
  }

  /// Set selected product
  void setSelectedProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Clear selected product
  /// Clear selected product
  void clearSelectedProduct() {
     _selectedProduct = null;
     notifyListeners();
  }

  // ==================== SEARCH & FILTER ====================

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Set category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Set price range filter
  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  /// Set rating filter
  void setMinRating(double? rating) {
    _minRating = rating;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _currentSortBy = 'newest';
    _applyFilters();
  }

  /// Apply filters to products
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Search query
      if (_searchQuery.isNotEmpty) {
        final matchesName = product.name.toLowerCase().contains(_searchQuery);
        final matchesDescription = product.description.toLowerCase().contains(_searchQuery);
        final matchesCategory = product.category.toLowerCase().contains(_searchQuery);
        
        if (!matchesName && !matchesDescription && !matchesCategory) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && product.category != _selectedCategory) {
        return false;
      }

      // Price filter
      if (_minPrice != null && product.price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && product.price > _maxPrice!) {
        return false;
      }

      // Rating filter
      if (_minRating != null && product.averageRating < _minRating!) {
        return false;
      }

      return true;
    }).toList();

    _sortFilteredProducts(_currentSortBy);

    notifyListeners();
  }

  // ==================== SORTING ====================

  /// Sort products
  void sortProducts(String sortBy) {
    _currentSortBy = sortBy;
    _sortFilteredProducts(sortBy);

    notifyListeners();
  }

  void _sortFilteredProducts(String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        _filteredProducts.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'newest':
        _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        break;
    }
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Add new product (admin only)
  Future<bool> addProduct(ProductModel product) async {
    try {
      await _productService.addProduct(product.toMap());

      // Refresh products
      await loadProducts(refresh: true);
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  /// Update product (admin only)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _productService.updateProduct(
        product.productId,
        product.toMap(),
      );

      // Update in local list
      final index = _products.indexWhere((p) => p.productId == product.productId);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  /// Delete product (admin only)
  Future<bool> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);

      // Remove from local list
      _products.removeWhere((p) => p.productId == productId);
      _applyFilters();

      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  /// Update product stock (employee/admin)
  Future<bool> updateStock(String productId, int newStock) async {
    try {
      await _productService.updateStock(productId, newStock);

      // Update in local list
      final index = _products.indexWhere((p) => p.productId == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStock);
        _applyFilters();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get product by ID from cache
  ProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get low stock products (for employee/admin)
  List<ProductModel> getLowStockProducts() {
    return _products.where((p) => p.lowStock).toList();
  }

  /// Get out of stock products (for employee/admin)
  List<ProductModel> getOutOfStockProducts() {
    return _products.where((p) => !p.inStock).toList();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadProducts(refresh: true);
    await loadFeaturedProducts();
  }
}
