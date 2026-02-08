import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/invoice_generator.dart';
import '../../shared/services/firebase_service.dart';

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
          queryBuilder: (q) => q.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true),
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
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  const Text('No orders found', style: TextStyle(color: AppColors.gray500)),
                  if (snapshot.hasError) ...[
                     const SizedBox(height: 8),
                     Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
                     TextButton(onPressed: () => (context as Element).markNeedsBuild(), child: const Text('Retry')),
                  ]
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data();
              if (orderData == null) {
                return const SizedBox.shrink();
              }
              final order = orderData as Map<String, dynamic>;
              final status = order['status'] ?? 'pending';
              final total = (order['totalAmount'] ?? 0.0).toDouble();
              final date = _parseDate(order['createdAt']);
              final items = (order['items'] as List?) ?? [];
              final orderId = orders[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ExpansionTile(
                  title: Row(
                    children: [
                       Text('Order #${orderId.substring(0, 6).toUpperCase()}'),
                       const Spacer(),
                       Text(Formatters.formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(Formatters.formatDate(date)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: _getStatusColor(status), fontWeight: FontWeight.bold),
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
                          ...items.map<Widget>((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Text('${item['quantity']}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(item['productName'] ?? 'Product')),
                                  Text(Formatters.formatCurrency((item['price'] ?? 0.0).toDouble())),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final pdfFile = await InvoiceGenerator.generateInvoice({...order, 'id': orderId});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invoice saved to ${pdfFile.path}'),
                                    backgroundColor: AppColors.primaryIndigo,
                                  ),
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

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
