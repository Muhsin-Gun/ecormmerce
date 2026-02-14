import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/constants.dart';
import '../models/user_model.dart';

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

    final uid = cred.user!.uid;

    // 👑 ROOT ADMIN BYPASS
    if (email.toLowerCase() == AppConstants.superAdminEmail.toLowerCase()) {
      await _ensureRootAdmin(uid, email);
    }

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User record missing');

    final user = UserModel.fromFirestore(doc);

    if (!user.isRoot && !user.emailVerified) {
      await _auth.signOut();
      throw Exception('$unverifiedEmailErrorCode|${user.email}|${user.name}');
    }

    if (user.role == 'admin' && !user.isApproved && !user.isRoot) {
      throw Exception('Admin approval pending');
    }

    return user;
  }

  /// 📝 REGISTER
  Future<void> register({
    required String email,
    required String password,
    required String role,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final isRoot =
        email.toLowerCase() == AppConstants.superAdminEmail.toLowerCase();

    // Create full user model (emailVerified starts as false)
    final user = UserModel(
      userId: uid,
      email: email,
      name: name,
      phone: phone,
      role: isRoot ? AppConstants.roleAdmin : role,
      roleStatus: (isRoot || role == AppConstants.roleClient)
          ? AppConstants.roleStatusApproved
          : AppConstants.roleStatusPending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRoot: isRoot,
      emailVerified: false, // Mark as not verified until OTP confirmed
    );

    await _db.collection('users').doc(uid).set(user.toMap());

    await logAction('REGISTER', email);
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
    await _db.collection('users').doc(user.userId).update(user.toMap());
  }

  /// 🚪 LOGOUT
  Future<void> logout() async => await _auth.signOut();
}
