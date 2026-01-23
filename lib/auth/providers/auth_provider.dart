import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/constants.dart';
import '../models/user_model.dart';
import '../../shared/services/firebase_service.dart';

/// Authentication Provider for managing user authentication and user state
/// Handles login, registration, role management, and user profile
class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  User? _firebaseUser;

  // ==================== GETTERS ====================

  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _userModel != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  // Role checks
  bool get isClient => _userModel?.isClient ?? false;
  bool get isEmployee => _userModel?.isEmployee ?? false;
  bool get isAdmin => _userModel?.isAdmin ?? false;

  // Status checks
  bool get isApproved => _userModel?.isApproved ?? false;
  bool get isPending => _userModel?.isPending ?? false;
  bool get isSuspended => _userModel?.isSuspended ?? false;
  bool get isRejected => _userModel?.isRejected ?? false;

  // ==================== INITIALIZATION ====================

  /// Initialize auth state
  Future<void> init() async {
    _setLoading(true);

    // Listen to auth state changes
    _firebaseService.auth.authStateChanges().listen(_onAuthStateChanged);

    // Load current user if logged in
    _firebaseUser = _firebaseService.currentUser;
    if (_firebaseUser != null) {
      await _loadUserData();
    }

    _setLoading(false);
  }

  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      await _loadUserData();
    } else {
      _userModel = null;
      notifyListeners();
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;

    try {
      final doc = await _firebaseService.getDocument(
        AppConstants.usersCollection,
        _firebaseUser!.uid,
      );

      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        _errorMessage = null;
      } else {
        // User document doesn't exist, might need to create it
        _userModel = null;
      }

      notifyListeners();
    } catch (e) {
      _setError('Error loading user data: ${e.toString()}');
    }
  }

  // ==================== REGISTRATION ====================

  /// Register new user with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Determine role status based on role
      String roleStatus;
      if (role == AppConstants.roleClient) {
        // Clients are auto-approved
        roleStatus = AppConstants.roleStatusApproved;
      } else {
        // Employees and Admins need approval
        roleStatus = AppConstants.roleStatusPending;
      }

      // Create user document in Firestore
      final userModel = UserModel(
        userId: user.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        roleStatus: roleStatus,
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        darkMode: true, // Default to dark mode
        notificationsEnabled: true,
      );

      await _firebaseService.setDocument(
        AppConstants.usersCollection,
        user.uid,
        userModel.toMap(),
      );

      // Send email verification
      await _firebaseService.sendEmailVerification();

      // Load user data
      _userModel = userModel;
      _firebaseUser = user;

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseService.getErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== LOGIN ====================

  /// Sign in with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      _firebaseUser = user;

      // Load user data
      await _loadUserData();

      if (_userModel == null) {
        throw Exception('User data not found');
      }

      // Check if user is suspended
      if (_userModel!.isSuspended) {
        await logout();
        _setError('Your account has been suspended. Please contact support.');
        return false;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseService.getErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== LOGOUT ====================

  /// Sign out
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _firebaseService.signOut();
      _userModel = null;
      _firebaseUser = null;
      _clearError();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    }

    _setLoading(false);
    notifyListeners();
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseService.getErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send reset email: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseService.getErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to change password: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== EMAIL VERIFICATION ====================

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.sendEmailVerification();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to send verification email: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Reload user to check email verification status
  Future<void> reloadUser() async {
    try {
      await _firebaseService.reloadUser();
      _firebaseUser = _firebaseService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  // ==================== PROFILE UPDATES ====================

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_userModel == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firebaseService.updateCurrentUserDocument(updates);

      // Update local user model
      _userModel = _userModel!.copyWith(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings(bool enabled) async {
    if (_userModel == null) return false;

    try {
      await _firebaseService.updateCurrentUserDocument({
        'notificationsEnabled': enabled,
      });

      _userModel = _userModel!.copyWith(notificationsEnabled: enabled);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update notification settings: ${e.toString()}');
      return false;
    }
  }

  // ==================== ROLE MANAGEMENT (ADMIN) ====================

  /// Approve user role (admin only)
  Future<bool> approveUserRole(String userId) async {
    if (!isAdmin) {
      _setError('Only admins can approve users');
      return false;
    }

    try {
      await _firebaseService.updateDocument(
        AppConstants.usersCollection,
        userId,
        {'roleStatus': AppConstants.roleStatusApproved},
      );
      return true;
    } catch (e) {
      _setError('Failed to approve user: ${e.toString()}');
      return false;
    }
  }

  /// Reject user role (admin only)
  Future<bool> rejectUserRole(String userId) async {
    if (!isAdmin) {
      _setError('Only admins can reject users');
      return false;
    }

    try {
      await _firebaseService.updateDocument(
        AppConstants.usersCollection,
        userId,
        {'roleStatus': AppConstants.roleStatusRejected},
      );
      return true;
    } catch (e) {
      _setError('Failed to reject user: ${e.toString()}');
      return false;
    }
  }

  /// Suspend user (admin only)
  Future<bool> suspendUser(String userId) async {
    if (!isAdmin) {
      _setError('Only admins can suspend users');
      return false;
    }

    try {
      await _firebaseService.updateDocument(
        AppConstants.usersCollection,
        userId,
        {'roleStatus': AppConstants.roleStatusSuspended},
      );
      return true;
    } catch (e) {
      _setError('Failed to suspend user: ${e.toString()}');
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    debugPrint('AuthProvider Error: $message');
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }
}
