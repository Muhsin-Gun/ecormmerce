import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/constants.dart';

class AuditLogService {
  AuditLogService._();

  static Future<void> log({
    required String action,
    required String target,
    Map<String, dynamic>? metadata,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.auditLogsCollection)
          .add({
        'action': action,
        'target': target,
        'by': user.email ?? user.uid,
        'uid': user.uid,
        'metadata': metadata ?? const <String, dynamic>{},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Audit log write failed: $e');
    }
  }
}
