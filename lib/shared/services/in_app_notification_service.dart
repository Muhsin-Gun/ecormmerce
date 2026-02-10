import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

class InAppNotificationService {
  InAppNotificationService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': type,
      'data': data ?? <String, dynamic>{},
    });
  }

  static Future<void> notifyRoles({
    required List<String> roles,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (roles.isEmpty) return;

    final users = await _firestore
        .collection('users')
        .where('role', whereIn: roles)
        .where('notificationsEnabled', isEqualTo: true)
        .get();

    if (users.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final userDoc in users.docs) {
      final notificationRef = userDoc.reference.collection('notifications').doc();
      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'data': data ?? <String, dynamic>{},
      });
    }
    await batch.commit();
  }

  static Future<void> notifyOrderPlaced({
    required String customerId,
    required String orderId,
    required String customerName,
  }) async {
    await notifyUser(
      userId: customerId,
      title: 'Order placed successfully',
      body: 'Your order #$orderId has been received and is now being processed.',
      type: 'order',
      data: {'orderId': orderId, 'status': 'pending'},
    );

    await notifyRoles(
      roles: const [UserModel.roleAdmin, UserModel.roleEmployee],
      title: 'New order received',
      body: '$customerName placed order #$orderId.',
      type: 'order',
      data: {'orderId': orderId, 'status': 'pending'},
    );
  }
}
