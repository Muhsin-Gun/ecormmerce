import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';

class FirstRunPermissionsGate extends StatefulWidget {
  final Widget child;
  const FirstRunPermissionsGate({super.key, required this.child});

  @override
  State<FirstRunPermissionsGate> createState() =>
      _FirstRunPermissionsGateState();
}

class _FirstRunPermissionsGateState extends State<FirstRunPermissionsGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapOnce());
  }

  Future<void> _bootstrapOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await NotificationService.requestPermissionOnceForUser(uid);
    } catch (e) {
      debugPrint('Permission bootstrap failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
