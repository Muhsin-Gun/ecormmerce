import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/screens/order_management_screen.dart';
import '../../admin/screens/admin_products_tab.dart'; // Employees can also manage inventory
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/screens/broadcast_notification_screen.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Colors.white, size: 40),
                  const SizedBox(width: AppTheme.spacingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Employee'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'Ready for today\'s tasks?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Tools Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.spacingM,
              crossAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.3,
              children: [
                _buildToolCard(
                  context,
                  title: 'Manage Orders',
                  icon: Icons.local_shipping,
                  color: AppColors.neonBlue,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen()));
                  },
                ),
                _buildToolCard(
                  context,
                  title: 'Manage Inventory',
                  icon: Icons.inventory,
                  color: AppColors.electricPurple,
                  onTap: () {
                    // Navigate to Products tab but maybe restricted mode in future
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsTab()));
                  },
                ),
                _buildToolCard(
                  context,
                  title: 'Customer Chat',
                  icon: Icons.chat,
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  title: 'Send Alerts',
                  icon: Icons.notifications_active,
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastNotificationScreen()));
                  },
                ),
                _buildToolCard(
                  context,
                  title: 'My Performance',
                  icon: Icons.bar_chart,
                  color: Colors.orange,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Performance Stats'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: Text('Orders Fulfilled'), trailing: Text('124')),
                            ListTile(title: Text('Avg. Rating'), trailing: Text('4.8/5.0')),
                            ListTile(title: Text('Active Chats'), trailing: Text('3')),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
