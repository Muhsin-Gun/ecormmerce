import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/services/firebase_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    selectedColor: AppColors.electricPurple.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.electricPurple : (isDark ? Colors.white : Colors.black),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.instance.getCollectionStream(
                'orders',
                queryBuilder: (query) => query.orderBy('createdAt', descending: true).limit(500),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                 if (snapshot.hasError) {
                   return const Center(
                     child: Text('Could not load orders right now.'),
                   );
                 }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, size: 64, color: AppColors.gray400),
                        const SizedBox(height: 16),
                        Text('No orders found', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                final allOrders = snapshot.data!.docs;
                final filteredOrders = _selectedStatus == 'All' 
                  ? allOrders 
                  : allOrders.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['status'] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase();
                    }).toList();

                if (filteredOrders.isEmpty) {
                  return const Center(child: Text('No matching orders for this status'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index].data() as Map<String, dynamic>;
                    final orderId = filteredOrders[index].id;
                    
                    return _buildOrderCard(context, orderId, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String orderId, Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final total = (order['totalAmount'] ?? 0.0).toDouble();
    final items = (order['items'] as List?) ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '#${orderId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  Formatters.formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo),
                ),
              ],
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${items.length} Items • ${order['userName'] ?? 'Unknown User'}'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  child: const Text('Update Status', style: TextStyle(color: AppColors.electricPurple)),
                  onSelected: (newStatus) {
                    _updateOrderStatus(orderId, newStatus);
                  },
                  itemBuilder: (context) => [
                    'processing', 'shipped', 'delivered', 'cancelled'
                  ].map((s) => PopupMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseService.instance.updateDocument('orders', orderId, {'status': newStatus});
      AppFeedback.success(context, 'Order updated to $newStatus');
    } catch (e) {
      AppFeedback.error(
        context,
        e,
        fallbackMessage: 'Could not update order.',
        nextStep: 'Please retry.',
      );
    }
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
