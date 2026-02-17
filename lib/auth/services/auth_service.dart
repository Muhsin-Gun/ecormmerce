import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/constants.dart';
import '../models/user_model.dart';

class RegistrationResult {
  final bool verificationEmailSent;

  const RegistrationResult({
    required this.verificationEmailSent,
  });
}

class AuthService {
  static const String unverifiedEmailErrorCode = 'UNVERIFIED_EMAIL';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// 🔐 LOGIN
  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.reload();

    final currentAuthUser = _auth.currentUser;
    if (currentAuthUser == null) {
      throw Exception('Unable to load your account. Please try again.');
    }

    final uid = currentAuthUser.uid;
    final firebaseVerified = currentAuthUser.emailVerified;

    // Root admin bypass
    if (email.toLowerCase() == AppConstants.superAdminEmail.toLowerCase()) {
      await _ensureRootAdmin(uid, email);
    }

    final doc = await _db.collection('users').doc(uid).get();
    late UserModel user;
    if (!doc.exists) {
      if (!firebaseVerified) {
        try {
          await currentAuthUser.sendEmailVerification();
        } catch (_) {
          // Keep login flow deterministic even if resend fails.
        }
        await _auth.signOut();
        throw Exception(
          '$unverifiedEmailErrorCode|${currentAuthUser.email ?? email}|',
        );
      }

      final resolvedEmail =
          (currentAuthUser.email ?? email).trim().toLowerCase();
      final fallbackUser = _buildUserModel(
        uid: uid,
        email: resolvedEmail,
        role: AppConstants.roleClient,
        name: _deriveDisplayName(email: resolvedEmail),
        phone: '',
      ).copyWith(
        emailVerified: true,
        updatedAt: DateTime.now(),
      );
      await _upsertUserDocument(fallbackUser);
      user = fallbackUser;
    } else {
      user = UserModel.fromFirestore(doc);
    }

    // CRITICAL: Update Firestore if Firebase Auth says verified
    if (!user.emailVerified && firebaseVerified) {
      await _db.collection('users').doc(uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // STRICT: Block login if email not verified (except root admin)
    if (!user.isRoot && !firebaseVerified) {
      try {
        await currentAuthUser.sendEmailVerification();
      } catch (_) {
        // Keep login flow deterministic even if resend fails.
      }
      await _auth.signOut();
      throw Exception('$unverifiedEmailErrorCode|${user.email}|${user.name}');
    }

    if (user.role == 'admin' && !user.isApproved && !user.isRoot) {
      throw Exception('Admin approval pending');
    }

    return user;
  }

  /// 📝 REGISTER
  Future<RegistrationResult> register({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    User? newlyCreatedUser;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      newlyCreatedUser = cred.user;
      if (newlyCreatedUser == null) {
        throw Exception('Unable to create account. Please try again.');
      }

      // CRITICAL: Verification email MUST be sent. Don't silently fail.
      try {
        await newlyCreatedUser.sendEmailVerification();
      } catch (emailError) {
        // Rollback account if we can't send verification email
        await _rollbackCreatedAuthUser(newlyCreatedUser);
        throw Exception(
          'Could not send verification email. Please check your internet and try again. Error: ${emailError.toString()}',
        );
      }

      unawaited(logAction('REGISTER', normalizedEmail));
      return RegistrationResult(verificationEmailSent: true);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } on FirebaseException catch (e) {
      await _rollbackCreatedAuthUser(newlyCreatedUser);
      throw Exception(_friendlyFirestoreError(e));
    } catch (e) {
      await _rollbackCreatedAuthUser(newlyCreatedUser);
      rethrow;
    }
  }

  UserModel _buildUserModel({
    required String uid,
    required String email,
    required String role,
    required String name,
    required String phone,
  }) {
    final isRoot =
        email.toLowerCase() == AppConstants.superAdminEmail.toLowerCase();
    final resolvedRole = isRoot ? AppConstants.roleAdmin : role;

    return UserModel(
      userId: uid,
      email: email,
      name: name,
      phone: phone,
      role: resolvedRole,
      roleStatus: (isRoot || resolvedRole == AppConstants.roleClient)
          ? AppConstants.roleStatusApproved
          : AppConstants.roleStatusPending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRoot: isRoot,
      emailVerified: false,
      darkMode: false,
    );
  }

  Future<void> _upsertUserDocument(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.userId)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> resendVerificationForExistingAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw Exception('Unable to access this account. Please sign in again.');
      }

      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) {
        throw Exception('Unable to access this account. Please sign in again.');
      }

      if (refreshed.emailVerified) {
        throw Exception('This email is already verified. Please sign in.');
      }

      await refreshed.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw Exception(
            'This email is already registered. Use the original password or reset password, then sign in.',
          );
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'too-many-requests':
          throw Exception('Too many attempts. Please wait a bit and retry.');
        case 'network-request-failed':
        case 'unavailable':
          throw Exception('Network issue. Check your connection and retry.');
        default:
          throw Exception(_friendlyAuthError(e));
      }
    } finally {
      await _auth.signOut();
    }
  }

  Future<void> completeEmailVerifiedSignup({
    required String name,
    required String phone,
    required String role,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('Session expired. Please sign in again.');
    }

    await current.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) {
      throw Exception('Session expired. Please sign in again.');
    }
    if (!refreshed.emailVerified) {
      throw Exception('Email is not verified yet.');
    }

    final uid = refreshed.uid;
    final docRef = _db.collection('users').doc(uid);
    final existingDoc = await docRef.get();
    if (existingDoc.exists) {
      await docRef.set(
        {
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final rawEmail = (refreshed.email ?? '').trim();
    if (rawEmail.isEmpty) {
      throw Exception('Unable to determine account email.');
    }

    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    final resolvedRole =
        role.trim().isEmpty ? AppConstants.roleClient : role.trim();
    final user = _buildUserModel(
      uid: uid,
      email: rawEmail.toLowerCase(),
      role: resolvedRole,
      name: normalizedName.isNotEmpty
          ? normalizedName
          : _deriveDisplayName(
              preferredName: refreshed.displayName,
              email: rawEmail,
            ),
      phone: normalizedPhone,
    ).copyWith(
      emailVerified: true,
      updatedAt: DateTime.now(),
    );

    await _upsertUserDocument(user);
    await logAction('REGISTER_VERIFIED', user.email);
  }

  Future<void> _rollbackCreatedAuthUser(User? user) async {
    if (user == null) {
      return;
    }
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with mixed case, number, and symbol.';
      case 'operation-not-allowed':
        return 'Email/Password sign-up is not enabled in Firebase Authentication.';
      case 'network-request-failed':
      case 'unavailable':
        return 'Network issue while creating account. Check your connection and retry.';
      case 'too-many-requests':
        return 'Too many sign-up attempts. Please wait and try again.';
      default:
        return e.message ?? 'Unable to create account right now.';
    }
  }

  String _friendlyFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Could not save your profile due to Firestore permissions. Deploy the latest rules and retry.';
      case 'unavailable':
        return 'Firestore is temporarily unavailable. Try again in a moment.';
      default:
        return e.message ??
            'Account setup failed while saving profile details.';
    }
  }

  String _deriveDisplayName({String? preferredName, required String email}) {
    final normalizedName = (preferredName ?? '').trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final localPart = email.split('@').first.trim();
    if (localPart.isNotEmpty) {
      return localPart;
    }
    return 'User';
  }

  /// ✅ APPROVE ADMIN (ONLY SUPER ADMIN SHOULD CALL THIS)
  Future<void> approveAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': true,
    });
    await logAction('ADMIN_APPROVED', uid);
  }

  /// ❌ REVOKE ADMIN (ONLY SUPER ADMIN SHOULD CALL THIS)
  Future<void> revokeAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': false,
    });
    await logAction('ADMIN_REVOKED', uid);
  }

  /// 👑 FORCE SUPER ADMIN
  Future<void> _ensureRootAdmin(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': 'admin',
      'isApproved': true,
      'isRoot': true,
    }, SetOptions(merge: true));
  }

  /// 📝 AUDIT LOGGING
  Future<void> logAction(String action, String target) async {
    try {
      await _db.collection('audit_logs').add({
        'action': action,
        'target': target,
        'timestamp': FieldValue.serverTimestamp(),
        'by': _auth.currentUser?.email,
      });
    } catch (e) {
      // Keep auth flows non-blocking when audit logging fails.
    }
  }

  /// 📧 SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 📧 SEND EMAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// 🔄 RELOAD USER
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// 🔄 UPDATE PROFILE
  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.userId).update({
      'name': user.name,
      'phone': user.phone,
      'profileImageUrl': user.profileImageUrl,
      'darkMode': user.darkMode,
      'notificationsEnabled': user.notificationsEnabled,
      'updatedAt': Timestamp.fromDate(user.updatedAt),
    });
  }

  /// 🚪 LOGOUT
  Future<void> logout() async => await _auth.signOut();
}
