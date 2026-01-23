import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/constants.dart';

/// Payment transaction model for tracking all payments
class PaymentModel extends Equatable {
  final String paymentId;
  final String orderId;
  final String userId;
  final double amount;
  final String method; // mpesa, card, cash
  final String status; // pending, processing, completed, failed, refunded
  
  // MPESA specific
  final String? mpesaPhoneNumber;
  final String? mpesaReceiptNumber;
  final String? mpesaTransactionId;
  final String? mpesaResultCode;
  final String? mpesaResultDescription;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? refundedAt;
  final String? failureReason;
  final String? refundReason;
  
  // Audit
  final Map<String, dynamic>? metadata;

  const PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.mpesaPhoneNumber,
    this.mpesaReceiptNumber,
    this.mpesaTransactionId,
    this.mpesaResultCode,
    this.mpesaResultDescription,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    this.refundedAt,
    this.failureReason,
    this.refundReason,
    this.metadata,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PaymentModel(
      paymentId: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? AppConstants.paymentMethodMpesa,
      status: data['status'] ?? AppConstants.paymentStatusPending,
      mpesaPhoneNumber: data['mpesaPhoneNumber'],
      mpesaReceiptNumber: data['mpesaReceiptNumber'],
      mpesaTransactionId: data['mpesaTransactionId'],
      mpesaResultCode: data['mpesaResultCode'],
      mpesaResultDescription: data['mpesaResultDescription'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      failedAt: data['failedAt'] != null
          ? (data['failedAt'] as Timestamp).toDate()
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] as Timestamp).toDate()
          : null,
      failureReason: data['failureReason'],
      refundReason: data['refundReason'],
      metadata: data['metadata'],
    );
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? AppConstants.paymentMethodMpesa,
      status: map['status'] ?? AppConstants.paymentStatusPending,
      mpesaPhoneNumber: map['mpesaPhoneNumber'],
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
      mpesaTransactionId: map['mpesaTransactionId'],
      mpesaResultCode: map['mpesaResultCode'],
      mpesaResultDescription: map['mpesaResultDescription'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] is Timestamp
              ? (map['completedAt'] as Timestamp).toDate()
              : DateTime.parse(map['completedAt']))
          : null,
      failedAt: map['failedAt'] != null
          ? (map['failedAt'] is Timestamp
              ? (map['failedAt'] as Timestamp).toDate()
              : DateTime.parse(map['failedAt']))
          : null,
      refundedAt: map['refundedAt'] != null
          ? (map['refundedAt'] is Timestamp
              ? (map['refundedAt'] as Timestamp).toDate()
              : DateTime.parse(map['refundedAt']))
          : null,
      failureReason: map['failureReason'],
      refundReason: map['refundReason'],
      metadata: map['metadata'],
    );
  }

  // ==================== TO MAP ====================

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'method': method,
      'status': status,
      'mpesaPhoneNumber': mpesaPhoneNumber,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'mpesaTransactionId': mpesaTransactionId,
      'mpesaResultCode': mpesaResultCode,
      'mpesaResultDescription': mpesaResultDescription,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'failureReason': failureReason,
      'refundReason': refundReason,
      'metadata': metadata,
    };
  }

  // ==================== COPY WITH ====================

  PaymentModel copyWith({
    String? paymentId,
    String? orderId,
    String? userId,
    double? amount,
    String? method,
    String? status,
    String? mpesaPhoneNumber,
    String? mpesaReceiptNumber,
    String? mpesaTransactionId,
    String? mpesaResultCode,
    String? mpesaResultDescription,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? refundedAt,
    String? failureReason,
    String? refundReason,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      mpesaPhoneNumber: mpesaPhoneNumber ?? this.mpesaPhoneNumber,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      mpesaTransactionId: mpesaTransactionId ?? this.mpesaTransactionId,
      mpesaResultCode: mpesaResultCode ?? this.mpesaResultCode,
      mpesaResultDescription: mpesaResultDescription ?? this.mpesaResultDescription,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      failureReason: failureReason ?? this.failureReason,
      refundReason: refundReason ?? this.refundReason,
      metadata: metadata ?? this.metadata,
    );
  }

  // ==================== STATUS CHECKS ====================

  bool get isPending => status == AppConstants.paymentStatusPending;
  bool get isProcessing => status == AppConstants.paymentStatusProcessing;
  bool get isCompleted => status == AppConstants.paymentStatusCompleted;
  bool get isFailed => status == AppConstants.paymentStatusFailed;
  bool get isRefunded => status == AppConstants.paymentStatusRefunded;

  bool get isMpesa => method == AppConstants.paymentMethodMpesa;
  bool get isCard => method == AppConstants.paymentMethodCard;
  bool get isCash => method == AppConstants.paymentMethodCash;

  // ==================== EQUATABLE ====================

  @override
  List<Object?> get props => [
        paymentId,
        orderId,
        userId,
        amount,
        method,
        status,
        mpesaPhoneNumber,
        mpesaReceiptNumber,
        mpesaTransactionId,
        mpesaResultCode,
        mpesaResultDescription,
        createdAt,
        completedAt,
        failedAt,
        refundedAt,
        failureReason,
        refundReason,
        metadata,
      ];
}
