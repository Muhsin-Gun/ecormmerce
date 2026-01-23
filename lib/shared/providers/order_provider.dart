import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/firebase_service.dart';
import '../../auth/models/user_model.dart';

/// Order Provider for managing orders
class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  OrderModel? _selectedOrder;
  
  bool _isLoading = false;
  String? _statusFilter;

  // ==================== GETTERS ====================

  List<OrderModel> get orders => _filteredOrders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  int get orderCount => _filteredOrders.length;

  // ==================== LOAD ORDERS ====================

  /// Load user orders
  Future<void> loadUserOrders(String userId) async {
    _setLoading(true);

    try {
      final snapshot = await _firebaseService.getCollection(
        AppConstants.ordersCollection,
        queryBuilder: (query) {
          return query
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(AppConstants.ordersPerPage);
        },
      );

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading user orders: $e');
    }

    _setLoading(false);
  }

  /// Load all orders (admin/employee)
  Future<void> loadAllOrders() async {
    _setLoading(true);

    try {
      final snapshot = await _firebaseService.getCollection(
        AppConstants.ordersCollection,
        queryBuilder: (query) {
          return query.orderBy('createdAt', descending: true);
        },
      );

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading all orders: $e');
    }

    _setLoading(false);
  }

  /// Load orders assigned to employee
  Future<void> loadEmployeeOrders(String employeeId) async {
    _setLoading(true);

    try {
      final snapshot = await _firebaseService.getCollection(
        AppConstants.ordersCollection,
        queryBuilder: (query) {
          return query
              .where('assignedToEmployeeId', isEqualTo: employeeId)
              .orderBy('createdAt', descending: true);
        },
      );

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading employee orders: $e');
    }

    _setLoading(false);
  }

  /// Load single order
  Future<void> loadOrder(String orderId) async {
    try {
      final doc = await _firebaseService.getDocument(
        AppConstants.ordersCollection,
        orderId,
      );

      if (doc.exists) {
        _selectedOrder = OrderModel.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading order: $e');
    }
  }

  // ==================== CREATE ORDER ====================

  /// Create new order from cart
  Future<String?> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required List<CartItemModel> cartItems,
    required AddressData deliveryAddress,
    required double subtotal,
    double? discount,
    double? deliveryFee,
    String? couponCode,
    String? customerNote,
  }) async {
    _setLoading(true);

    try {
      // Convert cart items to order items
      final orderItems = cartItems
          .map((item) => OrderItem.fromCartItem(item))
          .toList();

      // Calculate total
      final total = subtotal - (discount ?? 0) + (deliveryFee ?? 0);

      // Create order model
      final order = OrderModel(
        orderId: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        items: orderItems,
        subtotal: subtotal,
        discount: discount,
        deliveryFee: deliveryFee,
        total: total,
        deliveryAddress: deliveryAddress,
        status: AppConstants.orderStatusPending,
        paymentStatus: AppConstants.paymentStatusPending,
        paymentMethod: AppConstants.paymentMethodMpesa,
        couponCode: couponCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerNote: customerNote,
      );

      // Save to Firestore
      final docRef = await _firebaseService.addDocument(
        AppConstants.ordersCollection,
        order.toMap(),
      );

      _selectedOrder = order.copyWith(orderId: docRef.id);
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      _setLoading(false);
      return null;
    }
  }

  // ==================== UPDATE ORDER ====================

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
      };

      // Add timestamp for specific statuses
      if (newStatus == AppConstants.orderStatusDelivered) {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == AppConstants.orderStatusCancelled) {
        updates['cancelledAt'] = FieldValue.serverTimestamp();
      }

      await _firebaseService.updateDocument(
        AppConstants.ordersCollection,
        orderId,
        updates,
      );

      // Update local order
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
      }

      if (_selectedOrder?.orderId == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(status: newStatus);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(
    String orderId,
    String paymentStatus, {
    String? mpesaReceiptNumber,
    String? mpesaTransactionId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'paymentStatus': paymentStatus,
        if (mpesaReceiptNumber != null) 'mpesaReceiptNumber': mpesaReceiptNumber,
        if (mpesaTransactionId != null) 'mpesaTransactionId': mpesaTransactionId,
        if (paymentStatus == AppConstants.paymentStatusCompleted)
          'mpesaTransactionDate': FieldValue.serverTimestamp(),
      };

      await _firebaseService.updateDocument(
        AppConstants.ordersCollection,
        orderId,
        updates,
      );

      // Update local order
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          paymentStatus: paymentStatus,
          mpesaReceiptNumber: mpesaReceiptNumber,
          mpesaTransactionId: mpesaTransactionId,
        );
        _applyFilters();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  /// Assign order to employee
  Future<bool> assignToEmployee(
    String orderId,
    String employeeId,
    String employeeName,
  ) async {
    try {
      await _firebaseService.updateDocument(
        AppConstants.ordersCollection,
        orderId,
        {
          'assignedToEmployeeId': employeeId,
          'assignedToEmployeeName': employeeName,
        },
      );

      // Update local order
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          assignedToEmployeeId: employeeId,
          assignedToEmployeeName: employeeName,
        );
        _applyFilters();
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning order: $e');
      return false;
    }
  }

  // ==================== CANCEL & REFUND ====================

  /// Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    return await updateOrderStatus(orderId, AppConstants.orderStatusCancelled);
  }

  /// Process refund
  Future<bool> processRefund(
    String orderId,
    double amount,
    String reason,
  ) async {
    try {
      await _firebaseService.updateDocument(
        AppConstants.ordersCollection,
        orderId,
        {
          'status': AppConstants.orderStatusRefunded,
          'refundAmount': amount,
          'refundReason': reason,
          'refundedAt': FieldValue.serverTimestamp(),
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return false;
    }
  }

  // ==================== FILTERS ====================

  /// Filter orders by status
  void filterByStatus(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  /// Apply filters
  void _applyFilters() {
    _filteredOrders = _orders.where((order) {
      if (_statusFilter != null && order.status != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _statusFilter = null;
    _applyFilters();
  }

  // ==================== HELPERS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setSelectedOrder(OrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  /// Get pending orders count
  int getPendingCount() {
    return _orders.where((o) => o.isPending).length;
  }

  /// Stream order updates
  Stream<OrderModel> streamOrder(String orderId) {
    return _firebaseService.streamDocument(
      AppConstants.ordersCollection,
      orderId,
    ).map((doc) => OrderModel.fromFirestore(doc));
  }

  /// Refresh orders
  Future<void> refresh(String userId) async {
    await loadUserOrders(userId);
  }
}
