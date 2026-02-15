import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('notification_campaigns').add({
      'title': _titleController.text.trim(),
      'body': _bodyController.text.trim(),
      'targetRole': _target,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'queued',
    });
    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign queued successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Send app notifications and email campaigns from here. Backend worker should process queued campaigns.',
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
            value: _target,
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
            label: Text(_sending ? 'Sending...' : 'Queue campaign'),
          ),
        ],
      ),
    );
  }
}
