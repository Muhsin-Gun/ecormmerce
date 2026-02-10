import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import '../../shared/providers/message_provider.dart';
import '../../shared/screens/chat_screen.dart';
import '../../shared/services/firebase_service.dart';

class SupportUtils {
  static Future<void> startSupportChat(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Find Admin UID
      final snapshot = await FirebaseService.instance.getCollection(
        AppConstants.usersCollection,
        queryBuilder: (query) => query
            .where('role', isEqualTo: 'admin')
            .where('email', isEqualTo: AppConstants.superAdminEmail),
      );

      String otherUserId;
      String otherUserName = 'ProMarket Support';

      if (snapshot.docs.isNotEmpty) {
        otherUserId = snapshot.docs.first.id;
      } else {
        if (context.mounted) Navigator.pop(context); // Remove loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support is currently offline')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final conversationId = await context.read<MessageProvider>().startConversation(
        currentUserId: auth.firebaseUser!.uid,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserRole: 'admin',
      );

      if (context.mounted) Navigator.pop(context); // Remove loading

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: conversationId,
              receiverName: otherUserName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Chat Error: $e');
      if (context.mounted) Navigator.pop(context); // Remove loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start chat')),
        );
      }
    }
  }
}
