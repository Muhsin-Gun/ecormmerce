import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart';
import '../models/user_model.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_feedback.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EmailVerificationService _emailVerificationService =
      EmailVerificationService();

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  String? _pendingVerificationName;
  int _otpCooldownSeconds = 30;
  int _otpRemainingResends = 3;
  bool _otpResendCapReached = false;

  UserModel? get userModel => _userModel;
  User? get firebaseUser => FirebaseAuth.instance.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get pendingVerificationName => _pendingVerificationName;
  int get otpCooldownSeconds => _otpCooldownSeconds;
  int get otpRemainingResends => _otpRemainingResends;
  bool get otpResendCapReached => _otpResendCapReached;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  // Compatibility getters for existing code
  bool get isAdmin => _userModel?.role == AppConstants.roleAdmin;
  bool get isEmployee => _userModel?.role == AppConstants.roleEmployee;
  bool get isClient => _userModel?.role == AppConstants.roleClient;
  bool get isApproved => _userModel?.isApproved ?? false;
  bool get isPending => _userModel?.isPending ?? false;
  bool get isEmailVerified =>
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;

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
      _pendingVerificationEmail = null;
      _pendingVerificationName = null;
      _setLoading(false);
      return true;
    } catch (e) {
      final rawError = e.toString().replaceFirst('Exception: ', '');
      if (rawError.startsWith(AuthService.unverifiedEmailErrorCode)) {
        final parts = rawError.split('|');
        if (parts.length >= 3) {
          _pendingVerificationEmail = parts[1];
          _pendingVerificationName = parts[2];
        } else {
          _pendingVerificationEmail = email;
          _pendingVerificationName = '';
        }
        _setError(
          'Your email is not verified. Enter the OTP code sent to your inbox.',
        );
      } else {
        _setError(rawError);
      }
      _setLoading(false);
      return false;
    }
  }

  /// 🔐 GOOGLE SIGN-IN
  Future<bool> signInWithGoogle({bool forceAccountChooser = false}) async {
    _clearError();
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        // Web: use Firebase popup flow to avoid direct People API calls.
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        if (forceAccountChooser) {
          googleProvider.setCustomParameters({'prompt': 'select_account'});
        }
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider)
            .timeout(const Duration(seconds: 25));
      } else {
        // Mobile/desktop: use google_sign_in and exchange tokens with Firebase.
        final googleSignIn = GoogleSignIn();
        if (forceAccountChooser) {
          try {
            await googleSignIn.disconnect();
          } catch (_) {
            await googleSignIn.signOut();
          }
        }
        final GoogleSignInAccount? googleUser =
            await googleSignIn.signIn().timeout(const Duration(seconds: 25));
        if (googleUser == null) {
          _setError('Google sign-in was canceled.');
          return false;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 25));
      }

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google Sign-In returned no Firebase user.');
      }

      // Check if user profile exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user profile
        final newUser = UserModel(
          userId: user.uid,
          email: user.email!,
          name: user.displayName ?? 'User',
          phone: user.phoneNumber ?? '',
          role: AppConstants.roleClient,
          roleStatus: AppConstants.roleStatusApproved,
          emailVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isRoot: false,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        _userModel = newUser;
      } else {
        // Load existing user profile
        _userModel = UserModel.fromFirestore(userDoc);
        if (_userModel != null &&
            !_userModel!.emailVerified &&
            (user.emailVerified || user.providerData.any(
              (provider) => provider.providerId == 'google.com',
            ))) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {
              'emailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          _userModel = _userModel!.copyWith(emailVerified: true);
        }
      }

      return true;
    } on TimeoutException {
      _setError('Google Sign-In timed out. Please try again.');
      return false;
    } catch (e) {
      _setError('Google Sign-In failed: ${e.toString()}');
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

  /// 📧 SEND OTP TO EMAIL
  Future<bool> sendOTPtoEmail({
    required String email,
    required String userName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _emailVerificationService.sendOTPtoEmailDetailed(
        email: email,
        userName: userName,
      );
      _updateOtpMeta(response);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 🔐 VERIFY OTP
  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _emailVerificationService.verifyOTP(
        email: email,
        otp: otp,
      );
      _pendingVerificationEmail = null;
      _pendingVerificationName = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// 📧 RESEND OTP
  Future<bool> resendOTP({
    required String email,
    required String userName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _emailVerificationService.resendOTPDetailed(
        email: email,
        userName: userName,
      );
      _updateOtpMeta(response);
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
    _pendingVerificationEmail = null;
    _pendingVerificationName = null;
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
    _errorMessage = AppFeedback.friendlyError(msg);
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearPendingVerification() {
    _pendingVerificationEmail = null;
    _pendingVerificationName = null;
    notifyListeners();
  }

  Future<void> logVerificationEvent({
    required String eventName,
    required String email,
    Map<String, dynamic>? meta,
  }) async {
    try {
      await _emailVerificationService.logClientEvent(
        eventName: eventName,
        email: email,
        meta: meta,
      );
    } catch (_) {}
  }

  Future<void> prepareGoogleAccountSwitch() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore Google SDK cleanup issues and continue to Firebase sign-out.
    }
    await FirebaseAuth.instance.signOut();
  }

  void _updateOtpMeta(Map<String, dynamic> response) {
    _otpCooldownSeconds = (response['cooldownSeconds'] as num?)?.toInt() ?? 30;
    _otpRemainingResends = (response['remainingResends'] as num?)?.toInt() ?? 0;
    _otpResendCapReached = response['resendCapReached'] == true;
    notifyListeners();
  }
}
