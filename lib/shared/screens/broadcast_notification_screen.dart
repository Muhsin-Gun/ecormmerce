import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/app_feedback.dart';
import '../../shared/services/audit_log_service.dart';

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends State<BroadcastNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      AppFeedback.info(
        context,
        'Enter both title and message before sending.',
      );
      return;
    }

    setState(() => _sending = true);

    final campaigns = FirebaseFirestore.instance.collection(
      'notification_campaigns',
    );
    final campaignRef = campaigns.doc();
    final startedAt = DateTime.now();

    try {
      await campaignRef.set({
        'title': title,
        'body': body,
        'targetRole': _target,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sending',
      });

      final users = await _targetedUsers();
      final delivered = await _fanOutNotifications(
        users,
        title: title,
        body: body,
      );
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;

      await campaignRef.update({
        'status': 'sent',
        'deliveredCount': delivered,
        'durationMs': durationMs,
        'sentAt': FieldValue.serverTimestamp(),
      });
      await AuditLogService.log(
        action: 'BROADCAST_SENT',
        target: campaignRef.id,
        metadata: {
          'target': _target,
          'deliveredCount': delivered,
        },
      );

      if (!mounted) return;
      AppFeedback.success(
        context,
        'Campaign sent to $delivered user(s).',
      );
    } catch (e, st) {
      await _markCampaignFailed(
        campaignRef: campaignRef,
        title: title,
        body: body,
        error: e,
      );
      await AuditLogService.log(
        action: 'BROADCAST_FAILED',
        target: campaignRef.id,
        metadata: {
          'target': _target,
          'error': e.toString(),
        },
      );
      debugPrint('Broadcast send failed: $e\n$st');

      if (!mounted) return;
      AppFeedback.error(
        context,
        e,
        fallbackMessage: 'Could not send campaign.',
        nextStep: 'Check network and retry.',
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _markCampaignFailed({
    required DocumentReference<Map<String, dynamic>> campaignRef,
    required String title,
    required String body,
    required Object error,
  }) async {
    try {
      await campaignRef.set({
        'title': title,
        'body': body,
        'targetRole': _target,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'failed',
        'error': error.toString(),
      }, SetOptions(merge: true));
    } catch (writeError) {
      debugPrint('Could not update campaign status to failed: $writeError');
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _targetedUsers() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .get();

    final notificationEnabledDocs = usersSnapshot.docs.where((doc) {
      final enabled = doc.data()['notificationsEnabled'];
      return enabled != false;
    }).toList();

    if (_target == 'all') {
      return notificationEnabledDocs;
    }

    final acceptedRoles = _target == 'user'
        ? <String>{AppConstants.roleClient, 'user'}
        : <String>{AppConstants.roleEmployee};

    return notificationEnabledDocs.where((doc) {
      final role = (doc.data()['role'] ?? '').toString().toLowerCase();
      return acceptedRoles.contains(role);
    }).toList();
  }

  Future<int> _fanOutNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users, {
    required String title,
    required String body,
  }) async {
    if (users.isEmpty) return 0;

    final firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int opCount = 0;
    int delivered = 0;

    for (final userDoc in users) {
      final notificationRef = userDoc.reference
          .collection(AppConstants.notificationsCollection)
          .doc();
      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'promo',
        'data': {
          'campaign': true,
          'target': _target,
        },
      });
      opCount++;
      delivered++;

      // Keep under Firestore batch limits.
      if (opCount >= 450) {
        await batch.commit();
        batch = firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
    return delivered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Campaigns are delivered immediately to users in-app. '
            'Phone push timing can still depend on FCM token/permission state and platform delivery.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Notification title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message body'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _target,
            decoration: const InputDecoration(labelText: 'Audience'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All users')),
              DropdownMenuItem(value: 'user', child: Text('Customers only')),
              DropdownMenuItem(value: 'employee', child: Text('Employees only')),
            ],
            onChanged: (value) => setState(() => _target = value ?? 'all'),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(_sending ? 'Sending now...' : 'Send Now'),
          ),
        ],
      ),
    );
  }
}
