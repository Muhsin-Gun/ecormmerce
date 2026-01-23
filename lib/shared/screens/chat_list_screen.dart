import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService.instance.getAllChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final unread = chat['unreadCount'] ?? 0;
              final lastMsgTime = (chat['lastMessageTime'] as Timestamp?)?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.electricPurple,
                  child: Text(
                    (chat['userName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(chat['userName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (lastMsgTime != null)
                      Text(
                        Formatters.formatDate(lastMsgTime),
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                  ],
                ),
                subtitle: Text(
                  chat['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.neonBlue, shape: BoxShape.circle),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () {
                  // Mark as read
                  ChatService.instance.markAsRead(chatId);
                  
                  // Navigate
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        receiverName: chat['userName'] ?? 'User',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
