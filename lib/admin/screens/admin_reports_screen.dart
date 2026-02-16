import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .snapshots();
    final ordersStream = FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .snapshots();
    final productsStream = FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersStream,
        builder: (context, usersSnap) {
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnap.hasError) {
            return _ErrorView(error: usersSnap.error.toString());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ordersStream,
            builder: (context, ordersSnap) {
              if (ordersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ordersSnap.hasError) {
                return _ErrorView(error: ordersSnap.error.toString());
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: productsStream,
                builder: (context, productsSnap) {
                  if (productsSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (productsSnap.hasError) {
                    return _ErrorView(error: productsSnap.error.toString());
                  }

                  final report = _ReportSnapshot.fromDocs(
                    users: usersSnap.data?.docs ?? const [],
                    orders: ordersSnap.data?.docs ?? const [],
                    products: productsSnap.data?.docs ?? const [],
                  );

                  return _ReportsBody(report: report);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final _ReportSnapshot report;
  const _ReportsBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Revenue',
                value: Formatters.formatCurrency(report.totalRevenue),
                subtitle: 'Net completed sales',
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Users',
                value: '${report.totalUsers}',
                subtitle: '${report.clients} clients',
                icon: Icons.groups_outlined,
                color: AppColors.neonBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Orders',
                value: '${report.totalOrders}',
                subtitle: '${report.pendingOrders} pending',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primaryIndigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Products',
                value: '${report.activeProducts}',
                subtitle: '${report.outOfStockProducts} out of stock',
                icon: Icons.inventory_2_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        _SectionCard(
          title: 'Revenue Trend (Last ${report.trendWindowDays} days)',
          trailing: Text(
            'Avg ${Formatters.formatCurrency(report.averageOrderValue)} / order',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
          ),
          child: SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: _safeInterval(report.monthlyRevenue),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}k',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= report.monthLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          report.monthLabels[i],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      report.monthlyRevenue.length,
                      (i) => FlSpot(i.toDouble(), report.monthlyRevenue[i]),
                    ),
                    isCurved: true,
                    color: AppColors.electricPurple,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.electricPurple.withValues(alpha: 0.16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _SectionCard(
          title: 'Role Distribution',
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 44,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: report.admins.toDouble(),
                    color: AppColors.error,
                    title: 'Admins\n${report.admins}',
                    radius: 56,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  PieChartSectionData(
                    value: report.employees.toDouble(),
                    color: AppColors.warning,
                    title: 'Employees\n${report.employees}',
                    radius: 56,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  PieChartSectionData(
                    value: report.clients.toDouble(),
                    color: AppColors.success,
                    title: 'Clients\n${report.clients}',
                    radius: 56,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _SectionCard(
          title: 'Download Reports',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _downloadReportPdf(context, report),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Download Summary PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadRevenuePdf(context, report),
                icon: const Icon(Icons.attach_money_outlined),
                label: const Text('Revenue PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadUsersPdf(context, report),
                icon: const Icon(Icons.people_outline),
                label: const Text('Users PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _safeInterval(List<double> values) {
    if (values.isEmpty) return 10;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 100) return 20;
    if (max <= 500) return 100;
    if (max <= 1000) return 200;
    return 500;
  }

  Future<void> _downloadReportPdf(
    BuildContext context,
    _ReportSnapshot report,
  ) async {
    final bytes = await _buildPdf(
      title: 'ProMarket - Executive Summary',
      rows: [
        ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
        ['Revenue', Formatters.formatCurrency(report.totalRevenue)],
        ['Total users', '${report.totalUsers}'],
        ['Admins', '${report.admins}'],
        ['Employees', '${report.employees}'],
        ['Clients', '${report.clients}'],
        ['Total orders', '${report.totalOrders}'],
        ['Pending orders', '${report.pendingOrders}'],
        ['Failed payments', '${report.failedPayments}'],
        ['Active products', '${report.activeProducts}'],
        ['Out of stock', '${report.outOfStockProducts}'],
      ],
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'promarket_summary_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _downloadRevenuePdf(
    BuildContext context,
    _ReportSnapshot report,
  ) async {
    final rows = <List<String>>[
      ['Total revenue', Formatters.formatCurrency(report.totalRevenue)],
      ['Average order value', Formatters.formatCurrency(report.averageOrderValue)],
      ['Total orders', '${report.totalOrders}'],
      ['Failed payments', '${report.failedPayments}'],
      ...List.generate(
        report.monthLabels.length,
        (i) => [
          'Revenue ${report.monthLabels[i]}',
          '${report.monthlyRevenue[i].toStringAsFixed(1)}k',
        ],
      ),
    ];

    final bytes = await _buildPdf(
      title: 'ProMarket - Revenue Report',
      rows: rows,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'promarket_revenue_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _downloadUsersPdf(
    BuildContext context,
    _ReportSnapshot report,
  ) async {
    final bytes = await _buildPdf(
      title: 'ProMarket - Users Report',
      rows: [
        ['Total users', '${report.totalUsers}'],
        ['Admins', '${report.admins}'],
        ['Employees', '${report.employees}'],
        ['Clients', '${report.clients}'],
        ['New users (7d)', '${report.newUsers7d}'],
        ['New users (24h)', '${report.newUsers24h}'],
      ],
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'promarket_users_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  Future<Uint8List> _buildPdf({
    required String title,
    required List<List<String>> rows,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(width: 0.4),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            headers: const ['Metric', 'Value'],
            data: rows,
          ),
        ],
      ),
    );

    return doc.save();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 10),
            const Text(
              'Could not load reports',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReportSnapshot {
  final int totalUsers;
  final int admins;
  final int employees;
  final int clients;
  final int newUsers24h;
  final int newUsers7d;

  final int totalOrders;
  final int pendingOrders;
  final int failedPayments;
  final double totalRevenue;
  final double averageOrderValue;
  final List<double> monthlyRevenue;
  final List<String> monthLabels;
  final int trendWindowDays;

  final int activeProducts;
  final int outOfStockProducts;

  const _ReportSnapshot({
    required this.totalUsers,
    required this.admins,
    required this.employees,
    required this.clients,
    required this.newUsers24h,
    required this.newUsers7d,
    required this.totalOrders,
    required this.pendingOrders,
    required this.failedPayments,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.monthlyRevenue,
    required this.monthLabels,
    required this.trendWindowDays,
    required this.activeProducts,
    required this.outOfStockProducts,
  });

  factory _ReportSnapshot.fromDocs({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  }) {
    final now = DateTime.now();
    final since24h = now.subtract(const Duration(hours: 24));
    final since7d = now.subtract(const Duration(days: 7));

    int admins = 0;
    int employees = 0;
    int clients = 0;
    int newUsers24h = 0;
    int newUsers7d = 0;

    for (final u in users) {
      final data = u.data();
      final role = (data['role'] ?? '').toString().toLowerCase();
      if (role == AppConstants.roleAdmin) admins++;
      if (role == AppConstants.roleEmployee) employees++;
      if (role == AppConstants.roleClient || role == 'user') clients++;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;
      if (createdAt.isAfter(since24h)) newUsers24h++;
      if (createdAt.isAfter(since7d)) newUsers7d++;
    }

    const trendWindowDays = 30;
    final trendStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: trendWindowDays - 1));

    int pendingOrders = 0;
    int failedPayments = 0;
    double totalRevenue = 0;
    int revenueOrders = 0;

    const bucketCount = 6;
    final bucketSize = (trendWindowDays / bucketCount).ceil();
    final monthStarts = List<DateTime>.generate(bucketCount, (i) {
      return trendStart.add(Duration(days: i * bucketSize));
    });
    final monthlyRevenue = List<double>.filled(bucketCount, 0.0);
    final monthLabels = monthStarts
        .map((date) => DateFormat('MMM d').format(date))
        .toList();

    for (final o in orders) {
      final data = o.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final paymentStatus = (data['paymentStatus'] ?? '').toString().toLowerCase();
      if (status == AppConstants.orderStatusPending ||
          status == AppConstants.orderStatusProcessing) {
        pendingOrders++;
      }
      if (paymentStatus == AppConstants.paymentStatusFailed) {
        failedPayments++;
      }

      final isRevenueOrder =
          status != AppConstants.orderStatusCancelled &&
          paymentStatus != AppConstants.paymentStatusFailed;
      if (!isRevenueOrder) continue;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null || createdAt.isBefore(trendStart)) {
        continue;
      }

      final totalRaw = data['totalAmount'] ?? data['total'] ?? 0;
      final total = totalRaw is num ? totalRaw.toDouble() : 0.0;
      totalRevenue += total;
      revenueOrders++;

      final diffDays = createdAt.difference(trendStart).inDays;
      var bucketIndex = diffDays ~/ bucketSize;
      if (bucketIndex < 0) bucketIndex = 0;
      if (bucketIndex >= bucketCount) bucketIndex = bucketCount - 1;
      monthlyRevenue[bucketIndex] += total / 1000;
    }

    for (var i = 0; i < bucketCount; i++) {
      final start = monthStarts[i];
      final end = i == bucketCount - 1
          ? now
          : monthStarts[i + 1].subtract(const Duration(days: 1));
      if (start.month == end.month) {
        monthLabels[i] = DateFormat('MMM d').format(start);
      } else {
        monthLabels[i] =
            '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      }
    }

    int outOfStock = 0;
    for (final p in products) {
      final stockRaw = p.data()['stock'] ?? 0;
      final stock = stockRaw is num ? stockRaw.toInt() : 0;
      if (stock <= 0) outOfStock++;
    }

    return _ReportSnapshot(
      totalUsers: users.length,
      admins: admins,
      employees: employees,
      clients: clients,
      newUsers24h: newUsers24h,
      newUsers7d: newUsers7d,
      totalOrders: orders.length,
      pendingOrders: pendingOrders,
      failedPayments: failedPayments,
      totalRevenue: totalRevenue,
      averageOrderValue: revenueOrders == 0 ? 0 : totalRevenue / revenueOrders,
      monthlyRevenue: monthlyRevenue,
      monthLabels: monthLabels,
      trendWindowDays: trendWindowDays,
      activeProducts: products.length,
      outOfStockProducts: outOfStock,
    );
  }
}
