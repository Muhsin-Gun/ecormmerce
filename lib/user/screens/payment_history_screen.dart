import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        itemCount: 5, // Mock data
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
        itemBuilder: (context, index) {
          return _buildPaymentTile(
            context,
            date: DateTime.now().subtract(Duration(days: index * 2)),
            amount: 2500.0 + (index * 150),
            method: 'M-PESA',
            status: index == 0 ? 'COMPLETED' : 'SUCCESS',
            orderId: 'ORD-#${10254 + index}',
          );
        },
      ),
    );
  }

  Widget _buildPaymentTile(BuildContext context, {required DateTime date, required double amount, required String method, required String status, required String orderId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(Formatters.formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(Formatters.formatDate(date), style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
