import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/constants.dart';

/// Centralized Firebase service for all Firebase operations
/// Provides a clean API for Firestore, Auth operations
class FirebaseService {
  // Singleton pattern
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AUTH GETTERS ====================

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  // ==================== AUTHENTICATION ====================

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }

  /// Reload current user
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error reloading user: $e');
      rethrow;
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error updating password: $e');
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // ==================== FIRESTORE CRUD ====================

  /// Get document by ID
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      debugPrint('Error getting document: $e');
      rethrow;
    }
  }

  /// Get collection
  Future<QuerySnapshot> getCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      return await query.get();
    } catch (e) {
      debugPrint('Error getting collection: $e');
      rethrow;
    }
  }

  /// Stream document
  Stream<DocumentSnapshot> streamDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// Stream collection
  Stream<QuerySnapshot> streamCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collection);
    
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    
    return query.snapshots();
  }

  /// Add document
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      // Add timestamps
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  /// Set document (create or replace)
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      // Add timestamps
      if (!data.containsKey('createdAt')) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(collection).doc(docId).set(
            data,
            SetOptions(merge: merge),
          );
    } catch (e) {
      debugPrint('Error setting document: $e');
      rethrow;
    }
  }

  /// Update document
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Add updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Get a new batch
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Commit a batch
  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error committing batch: $e');
      rethrow;
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      debugPrint('Error running transaction: $e');
      rethrow;
    }
  }

  // ==================== QUERIES ====================

  /// Get documents with pagination
  Future<QuerySnapshot> getPaginatedDocuments(
    String collection, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      query = query.limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      return await query.get();
    } catch (e) {
      debugPrint('Error getting paginated documents: $e');
      rethrow;
    }
  }

  /// Search documents by field
  Future<QuerySnapshot> searchDocuments(
    String collection,
    String field,
    dynamic value,
  ) async {
    try {
      return await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
    } catch (e) {
      debugPrint('Error searching documents: $e');
      rethrow;
    }
  }

  // ==================== USER-SPECIFIC HELPERS ====================

  /// Get current user document
  Future<DocumentSnapshot> getCurrentUserDocument() async {
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    return await getDocument(AppConstants.usersCollection, currentUserId!);
  }

  /// Stream current user document
  Stream<DocumentSnapshot> streamCurrentUserDocument() {
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    return streamDocument(AppConstants.usersCollection, currentUserId!);
  }

  /// Update current user document
  Future<void> updateCurrentUserDocument(Map<String, dynamic> data) async {
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    await updateDocument(AppConstants.usersCollection, currentUserId!, data);
  }

  // ==================== EXISTENCE CHECKS ====================

  /// Check if document exists
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await getDocument(collection, docId);
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking document existence: $e');
      return false;
    }
  }

  /// Count documents in collection
  Future<int> countDocuments(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error counting documents: $e');
      return 0;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        case 'requires-recent-login':
          return 'Please log in again to continue.';
        default:
          return error.message ?? AppConstants.errorAuth;
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AppConstants.errorPermission;
        case 'not-found':
          return AppConstants.errorNotFound;
        case 'unavailable':
          return AppConstants.errorNetwork;
        default:
          return error.message ?? AppConstants.errorGeneric;
      }
    }
    
    return AppConstants.errorGeneric;
  }
}
