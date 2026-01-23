import 'package:equatable/equatable.dart';

/// Address model for delivery addresses
class AddressModel extends Equatable {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String recipientName;
  final String recipientPhone;
  final String street;
  final String city;
  final String postalCode;
  final String? country;
  final String? additionalInfo; // Apartment number, landmark, etc.
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.recipientName,
    required this.recipientPhone,
    required this.street,
    required this.city,
    required this.postalCode,
    this.country,
    this.additionalInfo,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  //  ==================== FACTORY CONSTRUCTORS ====================

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      label: map['label'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientPhone: map['recipientPhone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'],
      additionalInfo: map['additionalInfo'],
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // ==================== TO MAP ====================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'additionalInfo': additionalInfo,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ==================== COPY WITH ====================

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? recipientName,
    String? recipientPhone,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    String? additionalInfo,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== HELPERS ====================

  /// Returns formatted full address
  String get fullAddress {
    final parts = <String>[
      street,
      if (additionalInfo != null && additionalInfo!.isNotEmpty) additionalInfo!,
      city,
      postalCode,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  /// Returns short address for display
  String get shortAddress {
    return '$street, $city';
  }

  // ==================== EQUATABLE ====================

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        recipientName,
        recipientPhone,
        street,
        city,
        postalCode,
        country,
        additionalInfo,
        isDefault,
        createdAt,
        updatedAt,
      ];
}
