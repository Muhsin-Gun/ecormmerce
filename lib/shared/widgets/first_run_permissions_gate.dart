import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrompts());
  }

  Future<void> _showPrompts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final doneKey = 'permission_prompts_done_$uid';
    if (prefs.getBool(doneKey) == true || !mounted) return;

    final allowNotifications = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Stay Updated'),
            content: const Text(
                'Allow ProMarket to send push and order email notifications?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No thanks')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Allow')),
            ],
          ),
        ) ??
        false;

    if (allowNotifications) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final allowLocation = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Use Your Location'),
            content: const Text(
                'Enable location so we can auto-fill your saved address for faster deliveries.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not now')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enable')),
            ],
          ),
        ) ??
        false;

    if (allowLocation) {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          await Geolocator.getCurrentPosition();
        }
      }
    }

    await prefs.setBool(doneKey, true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
