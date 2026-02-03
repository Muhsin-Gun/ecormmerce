import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/screens/order_management_screen.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/section_header.dart';
import 'admin_products_tab.dart';
import 'user_management_screen.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_approval_screen.dart';
import 'audit_logs_screen.dart';
import 'admin_reports_screen.dart';
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/services/data_seeder.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await authProvider.signOut();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDashboardStats(),
        builder: (context, statsSnapshot) {
          final stats = statsSnapshot.data ?? {
            'revenue': 0.0,
            'orders': 0,
            'users': 0,
            'chartData': <double>[0, 0, 0, 0, 0, 0, 0],
          };
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Key Metrics Cards
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildMetricCard(
                        context,
                        title: 'Total Revenue',
                        value: 'KES ${(stats['revenue'] / 1000).toStringAsFixed(1)}K', 
                        trend: '+12%',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                        isLoading: statsSnapshot.connectionState == ConnectionState.waiting,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      _buildMetricCard(
                        context,
                        title: 'Total Orders',
                        value: '${stats['orders']}',
                        trend: '+5%',
                        icon: Icons.shopping_bag,
                        color: AppColors.electricPurple,
                        isLoading: statsSnapshot.connectionState == ConnectionState.waiting,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      _buildMetricCard(
                        context,
                        title: 'Active Users',
                        value: '${stats['users']}',
                        trend: '+8%',
                        icon: Icons.people,
                        color: AppColors.neonBlue,
                        isLoading: statsSnapshot.connectionState == ConnectionState.waiting,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // 2. Revenue Chart
                const SectionHeader(title: 'Revenue Analytics'),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(
                                titles[value.toInt() % titles.length],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(7, (index) {
                        final chartData = stats['chartData'] as List<double>;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: chartData[index],
                              color: AppColors.electricPurple,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // 3. Quick Actions Grid
                const SectionHeader(title: 'Management'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppTheme.spacingM,
                  crossAxisSpacing: AppTheme.spacingM,
                  childAspectRatio: 1.5,
                  children: [
                    _buildActionCard(
                      context,
                      title: 'Products',
                      icon: Icons.inventory_2,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsTab()));
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Orders',
                      icon: Icons.local_shipping,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen()));
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Users',
                      icon: Icons.group,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Reports',
                      icon: Icons.bar_chart,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Messages',
                      icon: Icons.message_outlined,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                      },
                    ),
                    _buildActionCard(
                      context,
                      title: 'Populate Inventory',
                      icon: Icons.cloud_download,
                      color: Colors.teal,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Add Real Products'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('This will add REAL products (iPhones, Nikes, etc.) with real images to your store.'),
                                SizedBox(height: 8),
                                Text('✅ Ready for App Demo', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Add Products'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Seeding Data...'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        try {
                          await DataSeeder.seedProducts();
                          // Users and Orders seeding removed as per request to avoid fake data
                          
                          if (context.mounted) Navigator.pop(context); // Dismiss loading
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Database seeded successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            // Refresh stats
                            (context as Element).markNeedsBuild();
                          }
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context); // Dismiss loading
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ),
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    try {
      final userCount = await FirebaseService.instance.countDocuments(AppConstants.usersCollection);
      final orderCount = await FirebaseService.instance.countDocuments(AppConstants.ordersCollection);
      
      final ordersSnapshot = await FirebaseService.instance.getCollection(
        AppConstants.ordersCollection,
        queryBuilder: (q) => q.where('status', isNotEqualTo: AppConstants.orderStatusCancelled),
      );
      
      double totalRevenue = 0;
      List<double> chartData = List.filled(7, 0.0);
      final now = DateTime.now();
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['totalAmount'] ?? 0).toDouble();
        totalRevenue += amount;
        
        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        if (createdAtTimestamp != null) {
          final createdAt = createdAtTimestamp.toDate();
          final diff = now.difference(createdAt).inDays;
          if (diff < 7) {
            chartData[6 - diff] += amount / 1000;
          }
        }
      }

      return {
        'revenue': totalRevenue,
        'orders': orderCount,
        'users': userCount,
        'chartData': chartData,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {
        'revenue': 0.0,
        'orders': 0,
        'users': 0,
        'chartData': List.filled(7, 0.0),
      };
    }
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
