import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/screens/broadcast_notification_screen.dart';
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/screens/order_management_screen.dart';
import '../../shared/widgets/section_header.dart';
import 'admin_approval_screen.dart';
import 'admin_products_tab.dart';
import 'admin_reports_screen.dart';
import 'audit_logs_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Broadcast',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BroadcastNotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, ordersSnap) {
          if (ordersSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orderStats = _buildOrderStats(ordersSnap.data?.docs ?? const []);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _usersStream(),
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final userStats = _buildUserStats(usersSnap.data?.docs ?? const []);

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _productsStream(),
                builder: (context, productsSnap) {
                  if (productsSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final productStats = _buildProductStats(
                    productsSnap.data?.docs ?? const [],
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 128,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildMetricCard(
                                context,
                                title: 'Revenue',
                                value: Formatters.formatCurrency(
                                  orderStats.totalRevenue,
                                ),
                                trend: _trendLabel(
                                  orderStats.todayRevenue,
                                  orderStats.yesterdayRevenue,
                                ),
                                icon: Icons.attach_money,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              _buildMetricCard(
                                context,
                                title: 'Orders',
                                value: '${orderStats.totalOrders}',
                                trend: _trendLabel(
                                  orderStats.todayOrders.toDouble(),
                                  orderStats.yesterdayOrders.toDouble(),
                                ),
                                icon: Icons.shopping_bag_outlined,
                                color: AppColors.electricPurple,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              _buildMetricCard(
                                context,
                                title: 'Customers',
                                value: '${userStats.totalClients}',
                                trend: _trendLabel(
                                  userStats.newClientsToday.toDouble(),
                                  userStats.newClientsYesterday.toDouble(),
                                ),
                                icon: Icons.people_outline,
                                color: AppColors.neonBlue,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              _buildMetricCard(
                                context,
                                title: 'Failed Payments',
                                value: '${orderStats.failedPayments}',
                                trend: orderStats.failedPayments == 0
                                    ? 'Healthy'
                                    : 'Needs attention',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildRevenueShowcase(context, orderStats: orderStats),
                        const SizedBox(height: AppTheme.spacingL),
                        const SectionHeader(title: 'Operational Snapshot'),
                        Wrap(
                          spacing: AppTheme.spacingS,
                          runSpacing: AppTheme.spacingS,
                          children: [
                            _infoChip(
                              'Pending Orders: ${orderStats.pendingOrders}',
                              AppColors.info,
                            ),
                            _infoChip(
                              'Low Stock: ${productStats.lowStock}',
                              AppColors.warning,
                            ),
                            _infoChip(
                              'Out of Stock: ${productStats.outOfStock}',
                              AppColors.error,
                            ),
                            _infoChip(
                              'Pending Admin Approvals: ${userStats.pendingAdminApprovals}',
                              AppColors.electricPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        const SectionHeader(title: 'Management'),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.9,
                          children: [
                            _buildActionCard(
                              context,
                              title: 'Products',
                              icon: Icons.inventory_2_outlined,
                              color: Colors.orange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminProductsTab(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Orders',
                              icon: Icons.local_shipping_outlined,
                              color: Colors.blue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const OrderManagementScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Users',
                              icon: Icons.group_outlined,
                              color: Colors.indigo,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserManagementScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Reports',
                              icon: Icons.bar_chart_outlined,
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminReportsScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Approvals',
                              icon: Icons.verified_user_outlined,
                              color: AppColors.electricPurple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminApprovalScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Audit Logs',
                              icon: Icons.history,
                              color: AppColors.neonBlue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuditLogsScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Broadcast',
                              icon: Icons.campaign_outlined,
                              color: Colors.teal,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BroadcastNotificationScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Messages',
                              icon: Icons.message_outlined,
                              color: Colors.purple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatListScreen(),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Logout',
                              icon: Icons.logout,
                              color: Colors.redAccent,
                              onTap: _confirmLogout,
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueShowcase(
    BuildContext context, {
    required _OrderStats orderStats,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bestDay = orderStats.dailyRevenueK.isEmpty
        ? 0.0
        : orderStats.dailyRevenueK.reduce((a, b) => a > b ? a : b);
    final weeklyRevenue = orderStats.dailyRevenueK.fold<double>(
      0,
      (runningTotal, value) => runningTotal + value,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.primaryIndigo.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                color: AppColors.primaryIndigo,
              ),
              const SizedBox(width: 8),
              Text(
                'Revenue Cockpit',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                _trendLabel(
                  orderStats.todayRevenue,
                  orderStats.yesterdayRevenue,
                ),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Last 7 days performance',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: bestDay <= 4 ? 1 : 2,
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final rounded = value.round();
                        if ((value - rounded).abs() > 0.001) {
                          return const SizedBox.shrink();
                        }
                        const labels = ['6d', '5d', '4d', '3d', '2d', '1d', 'Today'];
                        final idx = rounded;
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  final value = orderStats.dailyRevenueK[index];
                  final isToday = index == 6;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 15,
                        color: isToday
                            ? AppColors.primaryIndigo
                            : AppColors.electricPurple.withValues(alpha: 0.70),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _compactStatTile(
                title: 'Today',
                value: Formatters.formatCurrency(orderStats.todayRevenue),
                color: AppColors.success,
              ),
              _compactStatTile(
                title: '7D Total',
                value: Formatters.formatCurrency(weeklyRevenue * 1000),
                color: AppColors.primaryIndigo,
              ),
              _compactStatTile(
                title: 'Best Day',
                value: Formatters.formatCurrency(bestDay * 1000),
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactStatTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 136,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
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
          border: Border.all(
            color: isDark ? AppColors.gray700 : AppColors.gray200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _trendLabel(double current, double previous) {
    if (current == 0 && previous == 0) return '0%';
    if (previous <= 0) return current > 0 ? '+100%' : '0%';
    final diff = ((current - previous) / previous) * 100;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(0)}%';
  }

  _OrderStats _buildOrderStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    double totalRevenue = 0;
    double todayRevenue = 0;
    double yesterdayRevenue = 0;
    int todayOrders = 0;
    int yesterdayOrders = 0;
    int pendingOrders = 0;
    int failedPayments = 0;
    final dailyRevenueK = List<double>.filled(7, 0.0);

    for (final doc in docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final paymentStatus =
          (data['paymentStatus'] ?? '').toString().toLowerCase();
      final isCancelled = status == AppConstants.orderStatusCancelled;
      final isFailedPayment = paymentStatus == AppConstants.paymentStatusFailed;
      final isRevenueOrder = !isCancelled && !isFailedPayment;

      final amountRaw = data['totalAmount'] ?? data['total'] ?? 0;
      final amount = amountRaw is num ? amountRaw.toDouble() : 0.0;

      if (isFailedPayment) failedPayments++;
      if (status == AppConstants.orderStatusPending ||
          status == AppConstants.orderStatusProcessing) {
        pendingOrders++;
      }

      if (isRevenueOrder) totalRevenue += amount;

      final createdAtTs = data['createdAt'] as Timestamp?;
      if (createdAtTs == null) continue;
      final createdAt = createdAtTs.toDate();
      final dayStart = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (dayStart == today) {
        todayOrders++;
        if (isRevenueOrder) todayRevenue += amount;
      } else if (dayStart == yesterday) {
        yesterdayOrders++;
        if (isRevenueOrder) yesterdayRevenue += amount;
      }

      final diff = today.difference(dayStart).inDays;
      if (diff >= 0 && diff < 7 && isRevenueOrder) {
        dailyRevenueK[6 - diff] += amount / 1000;
      }
    }

    return _OrderStats(
      totalRevenue: totalRevenue,
      totalOrders: docs.length,
      todayRevenue: todayRevenue,
      yesterdayRevenue: yesterdayRevenue,
      todayOrders: todayOrders,
      yesterdayOrders: yesterdayOrders,
      pendingOrders: pendingOrders,
      failedPayments: failedPayments,
      dailyRevenueK: dailyRevenueK,
    );
  }

  _UserStats _buildUserStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int totalClients = 0;
    int newClientsToday = 0;
    int newClientsYesterday = 0;
    int pendingAdminApprovals = 0;

    for (final doc in docs) {
      final data = doc.data();
      final role = (data['role'] ?? '').toString().toLowerCase();
      final roleStatus = (data['roleStatus'] ?? '').toString().toLowerCase();
      final isApproved = data['isApproved'] == true;

      if (role == AppConstants.roleClient) {
        totalClients++;
        final createdAtTs = data['createdAt'] as Timestamp?;
        if (createdAtTs != null) {
          final dt = createdAtTs.toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          if (day == today) newClientsToday++;
          if (day == yesterday) newClientsYesterday++;
        }
      }

      if (role == AppConstants.roleAdmin &&
          (roleStatus == AppConstants.roleStatusPending || !isApproved)) {
        pendingAdminApprovals++;
      }
    }

    return _UserStats(
      totalClients: totalClients,
      newClientsToday: newClientsToday,
      newClientsYesterday: newClientsYesterday,
      pendingAdminApprovals: pendingAdminApprovals,
    );
  }

  _ProductStats _buildProductStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int lowStock = 0;
    int outOfStock = 0;
    for (final doc in docs) {
      final data = doc.data();
      final stockRaw = data['stock'] ?? 0;
      final stock = stockRaw is num ? stockRaw.toInt() : 0;
      if (stock <= 0) {
        outOfStock++;
      } else if (stock <= 5) {
        lowStock++;
      }
    }
    return _ProductStats(lowStock: lowStock, outOfStock: outOfStock);
  }
}

class _OrderStats {
  final double totalRevenue;
  final int totalOrders;
  final double todayRevenue;
  final double yesterdayRevenue;
  final int todayOrders;
  final int yesterdayOrders;
  final int pendingOrders;
  final int failedPayments;
  final List<double> dailyRevenueK;

  const _OrderStats({
    required this.totalRevenue,
    required this.totalOrders,
    required this.todayRevenue,
    required this.yesterdayRevenue,
    required this.todayOrders,
    required this.yesterdayOrders,
    required this.pendingOrders,
    required this.failedPayments,
    required this.dailyRevenueK,
  });
}

class _UserStats {
  final int totalClients;
  final int newClientsToday;
  final int newClientsYesterday;
  final int pendingAdminApprovals;

  const _UserStats({
    required this.totalClients,
    required this.newClientsToday,
    required this.newClientsYesterday,
    required this.pendingAdminApprovals,
  });
}

class _ProductStats {
  final int lowStock;
  final int outOfStock;

  const _ProductStats({
    required this.lowStock,
    required this.outOfStock,
  });
}
