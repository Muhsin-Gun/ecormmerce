import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/message_model.dart';
import '../../shared/providers/message_provider.dart';
import '../../core/utils/support_utils.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SupportUtils.startSupportChat(context, forceNew: true),
        backgroundColor: AppColors.electricPurple,
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text('New Chat', style: TextStyle(color: Colors.white)),
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
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact our support team for help',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => SupportUtils.startSupportChat(context, forceNew: true),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: AppColors.electricPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                
                // Find other participant
                String otherUserName = 'Unknown';
                
                for (final id in conversation.participants) {
                  if (id != currentUser?.uid) {
                    otherUserName = conversation.participantNames[id] ?? 'Unknown';
                    break;
                  }
                }

                final lastDate = conversation.lastMessageTime ?? DateTime.now();
                final formattedDate = DateTime.now().difference(lastDate).inDays > 0
                    ? DateFormat('MMM d').format(lastDate)
                    : DateFormat('HH:mm').format(lastDate);

                final isUnread = conversation.unreadCount > 0 && conversation.lastSenderId != currentUser?.uid;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    // Mark as read
                    context.read<MessageProvider>().markAsRead(conversation.id, currentUser?.uid ?? '');
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
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.electricPurple.withOpacity(0.1),
                        child: Text(
                          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.electricPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                       .shimmer(delay: 3000.ms, duration: 1500.ms),
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
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1000.ms),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.darkBackground : Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    otherUserName,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, 
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    conversation.lastMessage?.text ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? (isDark ? Colors.white : Colors.black) : (isDark ? AppColors.gray400 : AppColors.gray600),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12, 
                          color: isUnread ? AppColors.electricPurple : AppColors.gray500,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isUnread)
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.electricPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.gray300),
                    ],
                  ),
                ).animate()
                 .fadeIn(delay: (100 * index).ms)
                 .slideX(begin: 0.1, curve: Curves.easeOutQuad);
              },
            );
        },
      ),
    );
  }
}
