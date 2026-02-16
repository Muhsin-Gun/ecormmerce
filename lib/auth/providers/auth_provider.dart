import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart';
import '../models/user_model.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/google_sign_in_ids.dart';
import '../../core/utils/app_feedback.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EmailVerificationService _emailVerificationService =
      EmailVerificationService();
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userDocSubscription;

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  String? _pendingVerificationName;
  int _otpCooldownSeconds = 30;
  int _otpRemainingResends = 3;
  bool _otpResendCapReached = false;
  bool _isInitialized = false;

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
  bool get isInitialized => _isInitialized;

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
    if (_isInitialized) return;

    _setLoading(true);
    _authStateSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen(_handleAuthStateChanged, onError: (error) {
      debugPrint('Auth state stream error: $error');
    });

    await _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
    _isInitialized = true;
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
    if (_isLoading) return false;

    _clearError();
    _setLoading(true);
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        if (forceAccountChooser) {
          googleProvider.setCustomParameters({'prompt': 'select_account'});
        }
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider)
            .timeout(const Duration(seconds: 15));
      } else {
        final useAppleClientId =
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
        final googleSignIn = GoogleSignIn(
          clientId: useAppleClientId ? GoogleSignInIds.iosClientId : null,
          serverClientId: GoogleSignInIds.androidClientId,
        );
        if (forceAccountChooser) {
          try {
            await googleSignIn.disconnect();
          } catch (_) {
            await googleSignIn.signOut();
          }
        }
        final GoogleSignInAccount? googleUser =
            await googleSignIn.signIn().timeout(const Duration(seconds: 15));
        if (googleUser == null) {
          _setError('Google sign-in was canceled.');
          return false;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if ((googleAuth.idToken ?? '').isEmpty &&
            (googleAuth.accessToken ?? '').isEmpty) {
          _setError('Google sign-in was canceled.');
          return false;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 15));
      }

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google Sign-In returned no Firebase user.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
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
        notifyListeners();
      } else {
        _userModel = UserModel.fromFirestore(userDoc);
        if (_userModel != null &&
            !_userModel!.emailVerified &&
            (user.emailVerified ||
                user.providerData.any(
                  (provider) => provider.providerId == 'google.com',
                ))) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
            {
              'emailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          _userModel = _userModel!.copyWith(emailVerified: true);
        }
        notifyListeners();
      }

      return true;
    } on TimeoutException {
      _setError('Google Sign-In timed out. Please try again.');
      return false;
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      if (code == 'popup-closed-by-user' ||
          code == 'cancelled-popup-request' ||
          code == 'web-context-cancelled') {
        _setError('Google sign-in was canceled.');
      } else {
        _setError('Google Sign-In failed: ${e.message ?? e.code}');
      }
      return false;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      if (lower.contains('sign_in_canceled') ||
          lower.contains('sign-in canceled') ||
          lower.contains('sign in canceled') ||
          lower.contains('cancelled') ||
          lower.contains('canceled')) {
        _setError('Google sign-in was canceled.');
        return false;
      }
      _setError('Google Sign-In failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
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
      await _refreshCurrentUserDoc();
      notifyListeners();
    } catch (e) {
      debugPrint('Reload user error: $e');
    }
  }

  /// 🚪 LOGOUT
  Future<void> signOut() async {
    await _authService.logout();
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _userModel = null;
    _pendingVerificationEmail = null;
    _pendingVerificationName = null;
    notifyListeners();
  }

  /// Alias for signOut for compatibility
  Future<void> logout() async => await signOut();

  /// 🔄 UPDATE PROFILE
  Future<void> updateProfile(UserModel updatedUser) async {
    final previous = _userModel;
    final optimistic = updatedUser.copyWith(updatedAt: DateTime.now());
    _userModel = optimistic;
    notifyListeners();

    try {
      await _authService.updateProfile(optimistic);
    } catch (e) {
      _userModel = previous;
      _setError(e.toString());
      notifyListeners();
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

  Future<void> _handleAuthStateChanged(User? user) async {
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (user == null) {
      _userModel = null;
      _pendingVerificationEmail = null;
      _pendingVerificationName = null;
      notifyListeners();
      return;
    }

    await _refreshCurrentUserDoc();
    notifyListeners();

    _userDocSubscription = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        _userModel = null;
      } else {
        final loaded = UserModel.fromFirestore(doc);
        final firebaseVerified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        _userModel = loaded.copyWith(
          emailVerified: loaded.emailVerified || firebaseVerified,
        );
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('User profile stream error: $error');
    });
  }

  Future<void> _refreshCurrentUserDoc() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _userModel = null;
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      _userModel = null;
      return;
    }

    final loaded = UserModel.fromFirestore(userDoc);
    final firebaseVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    _userModel = loaded.copyWith(
      emailVerified: loaded.emailVerified || firebaseVerified,
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
