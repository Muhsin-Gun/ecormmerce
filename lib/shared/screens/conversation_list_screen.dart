import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/message_model.dart';
import '../../shared/providers/message_provider.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.read<AuthProvider>().firebaseUser;
    final messageProvider = context.read<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: messageProvider.streamConversations(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.electricPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppColors.electricPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start chatting with support from product pages',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              
              // Find other participant
              String otherUserId = '';
              String otherUserName = 'Unknown';
              
              for (final id in conversation.participants) {
                if (id != currentUser?.uid) {
                  otherUserId = id;
                  otherUserName = conversation.participantNames[id] ?? 'Unknown';
                  break;
                }
              }

              final lastDate = conversation.lastMessageTime ?? DateTime.now();
              final formattedDate = DateTime.now().difference(lastDate).inDays > 0
                  ? DateFormat('MMM d').format(lastDate)
                  : DateFormat('HH:mm').format(lastDate);

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conversation.id,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppColors.electricPurple,
                  child: Text(
                    otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  conversation.lastMessage?.text ?? 'Image/File',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 4),
                    // Unread badge placeholder
                    // if (unreadCount > 0) Container(...)
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
