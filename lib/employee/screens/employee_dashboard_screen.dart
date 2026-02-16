import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../admin/screens/admin_products_tab.dart';
import '../../admin/screens/admin_reports_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/message_provider.dart';
import '../../shared/screens/broadcast_notification_screen.dart';
import '../../shared/screens/chat_screen.dart';
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/screens/order_management_screen.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final uid = context.watch<AuthProvider>().firebaseUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Hub'),
        actions: [
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.message_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B46), Color(0xFF27477B), Color(0xFF4366A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user?.name ?? 'Employee'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Live support, order operations, and campaign controls in one place.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _LiveCountCard(
                      title: 'Pending Orders',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.warning,
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('status', whereIn: const ['pending', 'processing'])
                          .snapshots(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LiveCountCard(
                      title: 'Active Chats',
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.success,
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .snapshots(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LiveCountCard(
                      title: 'Campaigns',
                      icon: Icons.campaign_outlined,
                      color: AppColors.primaryIndigo,
                      stream: FirebaseFirestore.instance
                          .collection('notification_campaigns')
                          .snapshots(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Workspace',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(
                [
                  _ActionCard(
                    title: 'Manage Orders',
                    subtitle: 'Update fulfillment status',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryIndigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderManagementScreen(),
                      ),
                    ),
                  ),
                  _ActionCard(
                    title: 'Messages',
                    subtitle: 'Respond to customers fast',
                    icon: Icons.message_outlined,
                    color: AppColors.electricPurple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatListScreen(),
                      ),
                    ),
                  ),
                  _ActionCard(
                    title: 'Broadcast',
                    subtitle: 'Send app-wide updates',
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BroadcastNotificationScreen(),
                      ),
                    ),
                  ),
                  _ActionCard(
                    title: 'Inventory',
                    subtitle: 'Review product catalog',
                    icon: Icons.storefront_outlined,
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProductsTab(),
                      ),
                    ),
                  ),
                  _ActionCard(
                    title: 'Revenue Report',
                    subtitle: 'Track live sales metrics',
                    icon: Icons.stacked_line_chart_outlined,
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReportsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.42,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Recent Broadcasts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CampaignPreviewCard(isDark: isDark),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Conversation Feed',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ConversationPreviewCard(currentUserId: uid),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _LiveCountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _LiveCountCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 6),
              Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignPreviewCard extends StatelessWidget {
  final bool isDark;

  const _CampaignPreviewCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notification_campaigns')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No campaigns yet.'),
            );
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final title = (data['title'] ?? 'Untitled').toString();
              final status = (data['status'] ?? 'sent').toString();
              final delivered = data['deliveredCount'] ?? 0;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  status == 'failed'
                      ? Icons.error_outline
                      : Icons.campaign_outlined,
                  color: status == 'failed' ? AppColors.error : AppColors.success,
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${status.toUpperCase()} - Delivered: $delivered'
                  '${createdAt != null ? ' - ${DateFormat('MMM d, HH:mm').format(createdAt)}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ConversationPreviewCard extends StatelessWidget {
  final String? currentUserId;

  const _ConversationPreviewCard({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .orderBy('updatedAt', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No conversations yet.'),
            );
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final participants = List<String>.from(data['participants'] ?? const []);
              final participantNames = Map<String, dynamic>.from(
                data['participantNames'] ?? const <String, dynamic>{},
              );
              final lastMessage = Map<String, dynamic>.from(
                data['lastMessage'] ?? const <String, dynamic>{},
              );

              String receiverName = 'Customer';
              for (final id in participants) {
                if (id != currentUserId) {
                  receiverName = (participantNames[id] ?? 'Customer').toString();
                  break;
                }
              }

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.electricPurple.withValues(alpha: 0.12),
                  child: Text(
                    receiverName.isNotEmpty ? receiverName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricPurple,
                    ),
                  ),
                ),
                title: Text(
                  receiverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  (lastMessage['text'] ?? 'No messages yet').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  if (currentUserId != null) {
                    context
                        .read<MessageProvider>()
                        .markAsRead(doc.id, currentUserId!);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: doc.id,
                        receiverName: receiverName,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

