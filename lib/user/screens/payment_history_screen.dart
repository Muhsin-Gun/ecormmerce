import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/firebase_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    
    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.instance.getCollectionStream(
          AppConstants.transactionsCollection,
          queryBuilder: (q) => q
              .where('userId', isEqualTo: user.userId)
              .orderBy('createdAt', descending: true),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_outlined, size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  const Text('No payment history found', style: TextStyle(color: AppColors.gray500)),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 8),
                    Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
                    TextButton(onPressed: () => (context as Element).markNeedsBuild(), child: const Text('Retry')),
                  ]
                ],
              ),
            );
          }

          final payments = snapshot.data!.docs
              .map((doc) => PaymentModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentTile(
                context,
                date: payment.createdAt,
                amount: payment.amount,
                method: payment.method.toUpperCase(),
                status: payment.status.toUpperCase(),
                orderId: payment.orderId,
              );
            },
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
