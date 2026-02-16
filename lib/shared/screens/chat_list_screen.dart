import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/message_model.dart';
import '../providers/message_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messageProvider = context.watch<MessageProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.firebaseUser;
    final isEmployee = authProvider.userModel?.role == 'employee';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEmployee ? 'Employee Message Center' : 'Admin Message Center'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: messageProvider.streamAllConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  Text('No conversations found', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              
              // Find other participant (if admin, find the client)
              String otherUserName = 'User';
              
              for (final id in conversation.participants) {
                if (id != currentUser?.uid) {
                  otherUserName = conversation.participantNames[id] ?? 'User';
                  break;
                }
              }

              final isUnread = conversation.unreadCount > 0 && conversation.lastSenderId != currentUser?.uid;
              final lastMsgTime = conversation.lastMessageTime;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryIndigo.withValues(alpha: 0.1),
                      child: Text(
                        otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primaryIndigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.darkBackground : Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      otherUserName, 
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 16,
                      )
                    ),
                    if (lastMsgTime != null)
                      Text(
                        Formatters.formatDate(lastMsgTime),
                        style: TextStyle(
                          fontSize: 12, 
                          color: isUnread ? AppColors.primaryIndigo : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  conversation.lastMessage?.text ?? 'No messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: isUnread ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                trailing: isUnread 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryIndigo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gray300),
                onTap: () {
                  // Mark as read
                  messageProvider.markAsRead(conversation.id, currentUser?.uid ?? '');
                  
                  // Navigate
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: conversation.id,
                        receiverName: otherUserName,
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
