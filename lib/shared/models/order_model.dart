import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/constants.dart';
import '../../auth/models/user_model.dart';
import 'cart_item_model.dart';

/// Order model for ProMarket
class OrderModel extends Equatable {
  final String orderId;
  final String userId;
  final String? userName;
  final String? userPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double? discount;
  final double? deliveryFee;
  final double total;
  
  // Delivery address
  final AddressData deliveryAddress;
  
  // Order status
  final String status; // pending, processing, packed, shipped, delivered, cancelled, refunded
  final String paymentStatus; // pending, processing, completed, failed, refunded
  final String paymentMethod; // mpesa, card, cash
  
  // MPESA details
  final String? mpesaReceiptNumber;
  final String? mpesaTransactionId;
  final DateTime? mpesaTransactionDate;
  
  // Coupon
  final String? couponCode;
  
  // Assignment (for employees)
  final String? assignedToEmployeeId;
  final String? assignedToEmployeeName;
  
  // Tracking
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  
  // Notes
  final String? customerNote;
  final String? adminNote;
  
  // Refund
  final double? refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.items,
    required this.subtotal,
    this.discount,
    this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.mpesaReceiptNumber,
    this.mpesaTransactionId,
    this.mpesaTransactionDate,
    this.couponCode,
    this.assignedToEmployeeId,
    this.assignedToEmployeeName,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.customerNote,
    this.adminNote,
    this.refundAmount,
    this.refundReason,
    this.refundedAt,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    
    return OrderModel(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? data['phoneNumber'] ?? '',
      items: (data['items'] as List?)
              ?.where((item) => item != null)
              .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? data['totalAmount'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      total: (data['total'] ?? data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: _parseAddress(data['deliveryAddress'] ?? data['shippingAddress']),
      status: data['status'] ?? AppConstants.orderStatusPending,
      paymentStatus: data['paymentStatus'] ?? AppConstants.paymentStatusPending,
      paymentMethod: data['paymentMethod'] ?? AppConstants.paymentMethodMpesa,
      mpesaReceiptNumber: data['mpesaReceiptNumber'],
      mpesaTransactionId: data['mpesaTransactionId'],
      mpesaTransactionDate: _parseMpesaDate(data['mpesaTransactionDate']),
      couponCode: data['couponCode'],
      assignedToEmployeeId: data['assignedToEmployeeId'],
      assignedToEmployeeName: data['assignedToEmployeeName'],
      createdAt: _parseMpesaDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseMpesaDate(data['updatedAt']) ?? DateTime.now(),
      deliveredAt: _parseMpesaDate(data['deliveredAt']),
      cancelledAt: _parseMpesaDate(data['cancelledAt']),
      customerNote: data['customerNote'],
      adminNote: data['adminNote'],
      refundAmount: (data['refundAmount'] ?? 0).toDouble(),
      refundReason: data['refundReason'],
      refundedAt: _parseMpesaDate(data['refundedAt']),
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? map['phoneNumber'] ?? '',
      items: (map['items'] as List?)
              ?.where((item) => item != null)
              .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? map['totalAmount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      total: (map['total'] ?? map['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: _parseAddress(map['deliveryAddress'] ?? map['shippingAddress']),
      status: map['status'] ?? AppConstants.orderStatusPending,
      paymentStatus: map['paymentStatus'] ?? AppConstants.paymentStatusPending,
      paymentMethod: map['paymentMethod'] ?? AppConstants.paymentMethodMpesa,
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
      mpesaTransactionId: map['mpesaTransactionId'],
      mpesaTransactionDate: _parseMpesaDate(map['mpesaTransactionDate']),
      couponCode: map['couponCode'],
      assignedToEmployeeId: map['assignedToEmployeeId'],
      assignedToEmployeeName: map['assignedToEmployeeName'],
      createdAt: _parseMpesaDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseMpesaDate(map['updatedAt']) ?? DateTime.now(),
      deliveredAt: _parseMpesaDate(map['deliveredAt']),
      cancelledAt: _parseMpesaDate(map['cancelledAt']),
      customerNote: map['customerNote'],
      adminNote: map['adminNote'],
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      refundReason: map['refundReason'],
      refundedAt: _parseMpesaDate(map['refundedAt']),
    );
  }

  // ==================== TO MAP ====================

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'total': total,
      'deliveryAddress': deliveryAddress.toMap(),
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'mpesaTransactionId': mpesaTransactionId,
      'mpesaTransactionDate': mpesaTransactionDate != null
          ? Timestamp.fromDate(mpesaTransactionDate!)
          : null,
      'couponCode': couponCode,
      'assignedToEmployeeId': assignedToEmployeeId,
      'assignedToEmployeeName': assignedToEmployeeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'customerNote': customerNote,
      'adminNote': adminNote,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
    };
  }

  // ==================== COPY WITH ====================

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? userName,
    String? userPhone,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? total,
    AddressData? deliveryAddress,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? mpesaReceiptNumber,
    String? mpesaTransactionId,
    DateTime? mpesaTransactionDate,
    String? couponCode,
    String? assignedToEmployeeId,
    String? assignedToEmployeeName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? customerNote,
    String? adminNote,
    double? refundAmount,
    String? refundReason,
    DateTime? refundedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      mpesaTransactionId: mpesaTransactionId ?? this.mpesaTransactionId,
      mpesaTransactionDate: mpesaTransactionDate ?? this.mpesaTransactionDate,
      couponCode: couponCode ?? this.couponCode,
      assignedToEmployeeId: assignedToEmployeeId ?? this.assignedToEmployeeId,
      assignedToEmployeeName: assignedToEmployeeName ?? this.assignedToEmployeeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      customerNote: customerNote ?? this.customerNote,
      adminNote: adminNote ?? this.adminNote,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      refundedAt: refundedAt ?? this.refundedAt,
    );
  }

  // ==================== STATUS CHECKS ====================

  bool get isPending => status == AppConstants.orderStatusPending;
  bool get isProcessing => status == AppConstants.orderStatusProcessing;
  bool get isShipped => status == AppConstants.orderStatusShipped;
  bool get isDelivered => status == AppConstants.orderStatusDelivered;
  bool get isCancelled => status == AppConstants.orderStatusCancelled;
  bool get isRefunded => status == AppConstants.orderStatusRefunded;

  bool get isPaymentPending => paymentStatus == AppConstants.paymentStatusPending;
  bool get isPaymentCompleted => paymentStatus == AppConstants.paymentStatusCompleted;
  bool get isPaymentFailed => paymentStatus == AppConstants.paymentStatusFailed;

  bool get canBeCancelled => isPending || isProcessing;

  // ==================== EQUATABLE ====================

  @override
  List<Object?> get props => [
        orderId,
        userId,
        userName,
        userPhone,
        items,
        subtotal,
        discount,
        deliveryFee,
        total,
        deliveryAddress,
        status,
        paymentStatus,
        paymentMethod,
        mpesaReceiptNumber,
        mpesaTransactionId,
        mpesaTransactionDate,
        couponCode,
        assignedToEmployeeId,
        assignedToEmployeeName,
        createdAt,
        updatedAt,
        deliveredAt,
        cancelledAt,
        customerNote,
        adminNote,
        refundAmount,
        refundReason,
        refundedAt,
      ];

  static DateTime? _parseMpesaDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      final valueString = value.toString();
      if (valueString.length == 14) {
        return DateTime.tryParse(
          '${valueString.substring(0, 4)}-${valueString.substring(4, 6)}-${valueString.substring(6, 8)}T${valueString.substring(8, 10)}:${valueString.substring(10, 12)}:${valueString.substring(12, 14)}Z',
        );
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      if (value.length == 14) {
        return DateTime.tryParse(
          '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}T${value.substring(8, 10)}:${value.substring(10, 12)}:${value.substring(12, 14)}Z',
        );
      }
    }
    return null;
  }
  static AddressData _parseAddress(dynamic value) {
    if (value is Map) {
      return AddressData.fromMap(Map<String, dynamic>.from(value));
    }
    if (value is String) {
      return AddressData(
        id: '',
        label: 'Delivery',
        street: value,
        city: '',
        postalCode: '',
      );
    }
    return const AddressData(
      id: '',
      label: '',
      street: '',
      city: '',
      postalCode: '',
    );
  }
}

/// Order item (product in an order)
class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  factory OrderItem.fromCartItem(CartItemModel cartItem) {
    return OrderItem(
      productId: cartItem.productId,
      productName: cartItem.productName,
      productImage: cartItem.productImage,
      price: cartItem.price,
      quantity: cartItem.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;

  @override
  List<Object?> get props => [productId, productName, productImage, price, quantity];
}
