import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/google_sign_in_ids.dart';
import '../../core/utils/app_feedback.dart';

class AuthProvider extends ChangeNotifier {
  static const Duration _registerTimeout = Duration(seconds: 45);

  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userDocSubscription;

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  String? _pendingVerificationName;
  String? _pendingSignupName;
  String? _pendingSignupPhone;
  String? _pendingSignupRole;
  bool _isInitialized = false;

  UserModel? get userModel => _userModel;
  User? get firebaseUser => FirebaseAuth.instance.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get pendingVerificationName => _pendingVerificationName;
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
    _pendingVerificationEmail = null;
    _pendingVerificationName = null;
    _pendingSignupName = null;
    _pendingSignupPhone = null;
    _pendingSignupRole = null;
    try {
      _userModel = await _authService.login(email, password);
      _pendingVerificationEmail = null;
      _pendingVerificationName = null;
      _pendingSignupName = null;
      _pendingSignupPhone = null;
      _pendingSignupRole = null;
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
          'Your email is not verified. Check your inbox for the verification link.',
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
      UserCredential? userCredential;

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
        try {
          final useAppleClientId =
              defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS;
          final googleSignIn = GoogleSignIn(
            clientId: useAppleClientId ? GoogleSignInIds.iosClientId : null,
            serverClientId: GoogleSignInIds.webClientId,
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
        } on FirebaseAuthException catch (e) {
          if (defaultTargetPlatform == TargetPlatform.android &&
              _isGoogleConfigError(code: e.code, message: e.message)) {
            userCredential = await _tryAndroidProviderFallback(
              forceAccountChooser: forceAccountChooser,
            );
            if (userCredential == null) {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
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
        final normalizedEmail = (user.email ?? '').trim().toLowerCase();
        if (normalizedEmail.isEmpty) {
          throw Exception('Google account email is missing.');
        }
        final isRootAdmin =
            normalizedEmail == AppConstants.superAdminEmail.toLowerCase();
        final newUser = UserModel(
          userId: user.uid,
          email: normalizedEmail,
          name: user.displayName ?? 'User',
          phone: user.phoneNumber ?? '',
          role: isRootAdmin ? AppConstants.roleAdmin : AppConstants.roleClient,
          roleStatus: AppConstants.roleStatusApproved,
          emailVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isRoot: isRootAdmin,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        _userModel = newUser;
        notifyListeners();
      } else {
        _userModel = UserModel.fromFirestore(userDoc);
        final normalizedEmail = (user.email ?? '').trim().toLowerCase();
        final shouldPromoteRoot =
            normalizedEmail == AppConstants.superAdminEmail.toLowerCase() &&
                _userModel != null &&
                (!_userModel!.isRoot ||
                    _userModel!.role != AppConstants.roleAdmin ||
                    !_userModel!.isApproved);
        if (shouldPromoteRoot) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
            {
              'role': AppConstants.roleAdmin,
              'roleStatus': AppConstants.roleStatusApproved,
              'isApproved': true,
              'isRoot': true,
              'emailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          _userModel = _userModel!.copyWith(
            role: AppConstants.roleAdmin,
            roleStatus: AppConstants.roleStatusApproved,
            isRoot: true,
            emailVerified: true,
          );
        }
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
      if (await _reconcileAuthenticatedUserAfterGoogleError()) {
        return true;
      }
      _setError('Google Sign-In timed out. Please try again.');
      return false;
    } on FirebaseAuthException catch (e) {
      if (await _reconcileAuthenticatedUserAfterGoogleError()) {
        return true;
      }
      final code = e.code.toLowerCase();
      if (code == 'popup-closed-by-user' ||
          code == 'cancelled-popup-request' ||
          code == 'web-context-cancelled') {
        _setError('Google sign-in was canceled.');
      } else if (_isGoogleConfigError(code: code, message: e.message)) {
        _setError(
          'Google sign-in config is incomplete for Android. Add SHA-1/SHA-256 for ${GoogleSignInIds.androidPackageName} in Firebase, then download a fresh google-services.json and rebuild.',
        );
      } else {
        _setError('Google Sign-In failed: ${e.message ?? e.code}');
      }
      return false;
    } catch (e) {
      if (await _reconcileAuthenticatedUserAfterGoogleError()) {
        return true;
      }
      final lower = e.toString().toLowerCase();
      if (lower.contains('sign_in_canceled') ||
          lower.contains('sign-in canceled') ||
          lower.contains('sign in canceled') ||
          lower.contains('cancelled') ||
          lower.contains('canceled')) {
        _setError('Google sign-in was canceled.');
        return false;
      }
      if (lower.contains('developer_error') ||
          lower.contains('api exception: 10') ||
          lower.contains('apiexception: 10') ||
          lower.contains('status code: 10')) {
        _setError(
          'Google sign-in config is incomplete for Android. Add SHA-1/SHA-256 for ${GoogleSignInIds.androidPackageName} in Firebase, then download a fresh google-services.json and rebuild.',
        );
        return false;
      }
      _setError('Google Sign-In failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _reconcileAuthenticatedUserAfterGoogleError() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      await _refreshCurrentUserDoc();
    } catch (e) {
      debugPrint('Google sign-in reconciliation warning: $e');
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<UserCredential?> _tryAndroidProviderFallback({
    required bool forceAccountChooser,
  }) async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      if (forceAccountChooser) {
        provider.setCustomParameters({'prompt': 'select_account'});
      }
      return await FirebaseAuth.instance
          .signInWithProvider(provider)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Google provider fallback failed: $e');
      return null;
    }
  }

  bool _isGoogleConfigError({String? code, String? message}) {
    final normalizedCode = (code ?? '').toLowerCase();
    final normalizedMessage = (message ?? '').toLowerCase();
    return normalizedCode == 'invalid-credential' ||
        normalizedMessage.contains('developer_error') ||
        normalizedMessage.contains('api exception: 10') ||
        normalizedMessage.contains('apiexception: 10') ||
        normalizedMessage.contains('status code: 10');
  }

  /// 📝 REGISTER
  Future<RegistrationResult?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService
          .register(
            email: email,
            password: password,
          )
          .timeout(_registerTimeout);
      _pendingVerificationEmail = email.trim().toLowerCase();
      _pendingVerificationName = name.trim();
      _pendingSignupName = name.trim();
      _pendingSignupPhone = phone.trim();
      _pendingSignupRole =
          role.trim().isEmpty ? AppConstants.roleClient : role.trim();
      return result;
    } on TimeoutException {
      // CRITICAL: Don't silently return success on timeout
      // The account may or may not exist - either way, the signup is FAILED
      _setError(
        'Sign up took too long. Check your internet connection and try again. Your account may not have been created.',
      );
      return null;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _setLoading(false);
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
      _setError(e);
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
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Reload Firebase user, then persist verified state to Firestore when needed.
  Future<bool> refreshEmailVerificationState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed == null || !refreshed.emailVerified) {
      return false;
    }

    try {
      await _setFirestoreEmailVerified(refreshed.uid);
    } catch (error) {
      debugPrint('Email verification persistence warning: $error');
    }

    try {
      await _refreshCurrentUserDoc();
    } catch (error) {
      debugPrint('Email verification refresh warning: $error');
      if (_userModel != null && !_userModel!.emailVerified) {
        _userModel = _userModel!.copyWith(emailVerified: true);
      }
    }
    notifyListeners();
    return true;
  }

  Future<bool> completeEmailVerifiedSignup({
    String? fallbackName,
    String? fallbackPhone,
    String? fallbackRole,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final resolvedName =
          (fallbackName ?? _pendingSignupName ?? currentUser?.displayName ?? '')
              .trim();
      final resolvedPhone = (fallbackPhone ?? _pendingSignupPhone ?? '').trim();
      final resolvedRole =
          (fallbackRole ?? _pendingSignupRole ?? AppConstants.roleClient)
              .trim();

      await _authService.completeEmailVerifiedSignup(
        name: resolvedName,
        phone: resolvedPhone,
        role: resolvedRole,
      );
      await _refreshCurrentUserDoc();
      _pendingSignupName = null;
      _pendingSignupPhone = null;
      _pendingSignupRole = null;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification email for an existing account.
  Future<bool> resendVerificationForExistingAccount({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService
          .resendVerificationForExistingAccount(
            email: email,
            password: password,
          )
          .timeout(_registerTimeout);
      _pendingVerificationEmail = email.trim().toLowerCase();
      return true;
    } on TimeoutException {
      _setError(
        'Resending verification email is taking too long. Please retry.',
      );
      return false;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
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
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Continue Firebase sign-out even if local Google SDK cleanup fails.
    }
    await _authService.logout();
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _userModel = null;
    _pendingVerificationEmail = null;
    _pendingVerificationName = null;
    _pendingSignupName = null;
    _pendingSignupPhone = null;
    _pendingSignupRole = null;
    notifyListeners();
  }

  /// Alias for signOut for compatibility
  Future<void> logout() async => await signOut();

  /// 🔄 UPDATE PROFILE
  Future<bool> updateProfile(UserModel updatedUser) async {
    final previous = _userModel;
    final optimistic = updatedUser.copyWith(updatedAt: DateTime.now());
    _userModel = optimistic;
    notifyListeners();

    try {
      await _authService.updateProfile(optimistic);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _userModel = previous;
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(Object error, {String? fallbackMessage}) {
    _errorMessage = AppFeedback.friendlyError(
      error,
      fallbackMessage: fallbackMessage,
    );
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

  Future<void> prepareGoogleAccountSwitch() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore Google SDK cleanup issues and continue to Firebase sign-out.
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (user == null) {
      _userModel = null;
      _pendingVerificationEmail = null;
      _pendingVerificationName = null;
      _pendingSignupName = null;
      _pendingSignupPhone = null;
      _pendingSignupRole = null;
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
        if (firebaseVerified && !loaded.emailVerified) {
          unawaited(
            _setFirestoreEmailVerified(user.uid).catchError(
              (error) => debugPrint('Email verification sync warning: $error'),
            ),
          );
        }
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
    if (firebaseVerified && !loaded.emailVerified) {
      try {
        await _setFirestoreEmailVerified(uid);
      } catch (error) {
        debugPrint('Email verification sync warning: $error');
      }
    }
    _userModel = loaded.copyWith(
      emailVerified: loaded.emailVerified || firebaseVerified,
    );
  }

  Future<void> _setFirestoreEmailVerified(String uid) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(
      {
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
