import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/constants.dart';
import '../models/user_model.dart';

class AuthService {
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
    if (email.toLowerCase() == ROOT_ADMIN_EMAIL.toLowerCase()) {
      await _ensureRootAdmin(uid, email);
    }

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User record missing');

    final user = UserModel.fromFirestore(doc);

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

    final isRoot = email.toLowerCase() == ROOT_ADMIN_EMAIL.toLowerCase();

    // Create full user model
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
      print('Audit log failed: $e');
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

  /// 🚪 LOGOUT
  Future<void> logout() async => await _auth.signOut();
}
