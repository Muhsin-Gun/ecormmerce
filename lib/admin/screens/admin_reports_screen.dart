import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/constants.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Reports')),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Distribution',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildUserDistributionChart(),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Order Status Distribution',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildOrderDistributionChart(),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Quick Stats',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildQuickStatsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.usersCollection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final users = snapshot.data!.docs;
        int admins = 0;
        int employees = 0;
        int clients = 0;

        for (var doc in users) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'client';
          if (role == 'admin') admins++;
          else if (role == 'employee') employees++;
          else clients++;
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: admins.toDouble(), title: 'Admin', color: Colors.redAccent, radius: 50),
                PieChartSectionData(value: employees.toDouble(), title: 'Staff', color: Colors.purpleAccent, radius: 50),
                PieChartSectionData(value: clients.toDouble(), title: 'Users', color: Colors.cyanAccent, radius: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDistributionChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.ordersCollection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final orders = snapshot.data!.docs;
        Map<String, int> counts = {};
        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          counts[status] = (counts[status] ?? 0) + 1;
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: BarChart(
            BarChartData(
              barGroups: counts.entries.indexed.map((e) {
                return BarChartGroupData(x: e.$1, barRods: [
                  BarChartRodData(toY: e.$2.value.toDouble(), color: AppColors.electricPurple)
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      if (val.toInt() < counts.length) {
                        return Text(counts.keys.elementAt(val.toInt()), style: const TextStyle(fontSize: 8, color: Colors.white));
                      }
                      return const Text('');
                    }
                  )
                )
              )
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsList() {
    return Column(
      children: [
        _buildStatTile('Total Revenue Generated', 'KES 1,245,000', Icons.monetization_on, Colors.green),
        _buildStatTile('Avg. Transaction Value', 'KES 12,400', Icons.trending_up, Colors.blue),
        _buildStatTile('Active Sessions Today', '145', Icons.visibility, Colors.orange),
      ],
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        trailing: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
