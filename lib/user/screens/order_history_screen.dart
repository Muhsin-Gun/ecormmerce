import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/invoice_generator.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/models/order_model.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.instance.currentUserId;

    if (userId == null) return const Scaffold(body: Center(child: Text('Please Login')));

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.instance.getCollectionStream(
          'orders',
          queryBuilder: (q) => q.where('userId', isEqualTo: userId),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                   const SizedBox(height: 16),
                   Text(
                     AppFeedback.friendlyError(
                       snapshot.error ?? 'Failed to load orders.',
                     ),
                     textAlign: TextAlign.center,
                   ),
                   TextButton(onPressed: () => (context as Element).markNeedsBuild(), child: const Text('Try Again')),
                 ],
               ),
             );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.gray400),
                  SizedBox(height: 16),
                  Text('No orders found', style: TextStyle(color: AppColors.gray500)),
                ],
              ),
            );
          }

          final ordersDocs = snapshot.data!.docs;
          
          // Parse and sort locally to avoid index issues
          final orders = ordersDocs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ExpansionTile(
                  title: Row(
                    children: [
                       Text('Order #${order.orderId.substring(0, 6).toUpperCase()}'),
                       const Spacer(),
                       Text(Formatters.formatCurrency(order.total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(Formatters.formatDate(order.createdAt)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...order.items.map<Widget>((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(item.productName)),
                                  Text(Formatters.formatCurrency(item.price)),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final pdfFile = await InvoiceGenerator.generateInvoice({...order.toMap(), 'id': order.orderId});
                                if (!context.mounted) return;
                                AppFeedback.success(
                                  context,
                                  'Invoice saved to ${pdfFile.path}',
                                );
                              },
                              icon: const Icon(Icons.download_for_offline),
                              label: const Text('Download Invoice'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'processing':
      case 'shipped':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
}
