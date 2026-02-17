import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/constants.dart';

/// User model for ProMarket
/// Supports role-based access (Client, Employee, Admin)
class UserModel extends Equatable {
  final String userId;
  final String email;
  final String name;
  final String? phone;
  final String role; // client, employee, admin
  final String roleStatus; // pending, approved, suspended, rejected
  final String? profileImageUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Preferences
  final bool darkMode;
  final bool notificationsEnabled;
  final bool isRoot;

  // Optional fields
  final List<AddressData>? addresses;
  final Map<String, dynamic>? preferences;

  const UserModel({
    required this.userId,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.roleStatus,
    this.profileImageUrl,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.isRoot = false,
    this.addresses,
    this.preferences,
  });

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Creates UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? AppConstants.roleClient,
      roleStatus: data['roleStatus'] ?? AppConstants.roleStatusApproved,
      profileImageUrl: data['profileImageUrl'],
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      darkMode: data['darkMode'] ?? false,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      isRoot: data['isRoot'] ?? false,
      addresses: data['addresses'] != null
          ? (data['addresses'] as List)
              .map((addr) => AddressData.fromMap(addr as Map<String, dynamic>))
              .toList()
          : null,
      preferences: data['preferences'],
    );
  }

  /// Creates UserModel from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? AppConstants.roleClient,
      roleStatus: map['roleStatus'] ?? AppConstants.roleStatusApproved,
      profileImageUrl: map['profileImageUrl'],
      emailVerified: map['emailVerified'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['updatedAt'] ?? DateTime.now().toIso8601String()),
      darkMode: map['darkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      isRoot: map['isRoot'] ?? false,
      addresses: map['addresses'] != null
          ? (map['addresses'] as List)
              .map((addr) => AddressData.fromMap(addr as Map<String, dynamic>))
              .toList()
          : null,
      preferences: map['preferences'],
    );
  }

  // ==================== TO MAP ====================

  /// Converts UserModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'roleStatus': roleStatus,
      'profileImageUrl': profileImageUrl,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'isRoot': isRoot,
      'addresses': addresses?.map((addr) => addr.toMap()).toList(),
      'preferences': preferences,
    };
  }

  // ==================== COPY WITH ====================

  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? roleStatus,
    String? profileImageUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? isRoot,
    List<AddressData>? addresses,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roleStatus: roleStatus ?? this.roleStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isRoot: isRoot ?? this.isRoot,
      addresses: addresses ?? this.addresses,
      preferences: preferences ?? this.preferences,
    );
  }

  // ==================== ROLE CHECKS ====================

  bool get isClient => role == AppConstants.roleClient;
  bool get isEmployee => role == AppConstants.roleEmployee;
  bool get isAdmin => role == AppConstants.roleAdmin;

  bool get isApproved => roleStatus == AppConstants.roleStatusApproved;
  bool get isPending => roleStatus == AppConstants.roleStatusPending;
  bool get isSuspended => roleStatus == AppConstants.roleStatusSuspended;
  bool get isRejected => roleStatus == AppConstants.roleStatusRejected;

  // ==================== EQUATABLE ====================

  @override
  List<Object?> get props => [
        userId,
        email,
        name,
        phone,
        role,
        roleStatus,
        profileImageUrl,
        emailVerified,
        createdAt,
        updatedAt,
        darkMode,
        notificationsEnabled,
        addresses,
        preferences,
      ];
  // UI Aliases
  String get uid => userId;
  String get phoneNumber => phone ?? '';
}

/// Address data for user
class AddressData extends Equatable {
  final String id;
  final String label; // Home, Work, etc.
  final String street;
  final String city;
  final String postalCode;
  final String? country;
  final bool isDefault;

  const AddressData({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
    this.country,
    this.isDefault = false,
  });

  factory AddressData.fromMap(Map<String, dynamic> map) {
    return AddressData(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  AddressData copyWith({
    String? id,
    String? label,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) {
    return AddressData(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props =>
      [id, label, street, city, postalCode, country, isDefault];

  // UI alias
  String get streetAddress => street;
}
