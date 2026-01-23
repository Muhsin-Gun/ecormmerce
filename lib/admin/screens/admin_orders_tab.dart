import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  void _showStatusUpdateDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: #${order.orderId.substring(0, 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(ctx, order.orderId, 'Pending', Icons.hourglass_empty, AppColors.warning),
            _buildStatusOption(ctx, order.orderId, 'Processing', Icons.sync, Colors.blue),
            _buildStatusOption(ctx, order.orderId, 'Shipped', Icons.local_shipping, Colors.purple),
            _buildStatusOption(ctx, order.orderId, 'Delivered', Icons.check_circle, AppColors.success),
            _buildStatusOption(ctx, order.orderId, 'Cancelled', Icons.cancel, AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext ctx, String orderId, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status),
      onTap: () async {
        Navigator.pop(ctx);
        await context.read<OrderProvider>().updateOrderStatus(orderId, status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.orders.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        return RefreshIndicator(
          onRefresh: () async => orderProvider.loadAllOrders(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: orderProvider.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orderProvider.orders[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order.orderId.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => _showStatusUpdateDialog(order),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(order.status)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    order.status,
                                    style: TextStyle(
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 12, color: _getStatusColor(order.status)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(order.userName ?? 'Guest'),
                          const Spacer(),
                          Text(
                            Formatters.formatCurrency(order.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryIndigo,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${order.deliveryAddress.city}, ${order.deliveryAddress.streetAddress}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM d, HH:mm').format(order.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            order.paymentMethod,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return AppColors.warning;
      case 'Processing': return Colors.blue;
      case 'Shipped': return Colors.purple;
      case 'Delivered': return AppColors.success;
      case 'Cancelled': return AppColors.error;
      default: return Colors.grey;
    }
  }
}
