import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../core/constants/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get userModel => _userModel;
  User? get firebaseUser => FirebaseAuth.instance.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  // Compatibility getters for existing code
  bool get isAdmin => _userModel?.role == AppConstants.roleAdmin;
  bool get isEmployee => _userModel?.role == AppConstants.roleEmployee;
  bool get isClient => _userModel?.role == AppConstants.roleClient;
  bool get isApproved => _userModel?.isApproved ?? false;
  bool get isPending => _userModel?.isPending ?? false;
  bool get isEmailVerified => FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  /// Initialize and load user data
  Future<void> init() async {
    _setLoading(true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _userModel = await _authService.login(user.email!, 'DUMMY_NOT_USED');
      } catch (e) {
        debugPrint('Auth init user load: $e');
      }
    }
    _setLoading(false);
  }

  /// 🔐 LOGIN
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      _userModel = await _authService.login(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 📝 REGISTER
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
      await _authService.register(
        email: email,
        password: password,
        role: role,
        name: name,
        phone: phone,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 📧 PASSWORD RESET
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 📧 EMAIL VERIFICATION
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendEmailVerification();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 🔄 RELOAD USER
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Reload user error: $e');
    }
  }

  /// 🚪 LOGOUT
  Future<void> signOut() async {
    await _authService.logout();
    _userModel = null;
    notifyListeners();
  }

  /// Alias for signOut for compatibility
  Future<void> logout() async => await signOut();

  /// 🔄 UPDATE PROFILE
  Future<void> updateProfile(UserModel updatedUser) async {
    _setLoading(true);
    try {
      await _authService.updateProfile(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg.replaceAll('Exception: ', '');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
