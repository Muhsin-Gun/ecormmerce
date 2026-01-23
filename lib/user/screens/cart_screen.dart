import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/cart_item_widget.dart'; // Assumed existing or will view/create
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDark ? AppColors.gray700 : AppColors.gray300,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? AppColors.gray500 : AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate back to home/products
                       Navigator.pop(context);
                    },
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: cart.items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: AppTheme.spacingM),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Hero(
                      tag: 'cart_item_${item.productId}',
                      child: CartItemWidget(
                        item: item,
                        onIncrement: () => cart.updateQuantity(item.productId, item.quantity + 1),
                        onDecrement: () => cart.updateQuantity(item.productId, item.quantity - 1),
                        onRemove: () => cart.removeItem(item.productId),
                      ),
                    );
                  },
                ),
              ),

              // Summary Section
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Coupon Code Input (Simplified)
                      if (cart.couponCode == null)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Enter coupon code',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onSubmitted: (value) => cart.applyCoupon(value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                // Trigger coupon dialog or logic
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Try "WELCOME" for 10% off')));
                              }, 
                              child: const Text('Apply'),
                            ),
                          ],
                        )
                      else
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text('Coupon: ${cart.couponCode}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                             IconButton(onPressed: () => cart.removeCoupon(), icon: const Icon(Icons.close, color: AppColors.error)),
                           ],
                         ),
                      
                      const SizedBox(height: AppTheme.spacingM),

                      // Totals
                      _buildSummaryRow('Subtotal', Formatters.formatCurrency(cart.subtotal), theme),
                      if (cart.discount > 0)
                        _buildSummaryRow('Discount', '-${Formatters.formatCurrency(cart.discountAmount)}', theme, color: AppColors.success),
                      const Divider(height: 24),
                      _buildSummaryRow('Total', Formatters.formatCurrency(cart.total), theme, isTotal: true),
                      
                      const SizedBox(height: AppTheme.spacingL),

                      // Checkout Button
                      AuthButton(
                        text: 'Checkout',
                        onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                           );
                        },
                        isLoading: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
              ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
          ),
          Text(
            value,
            style: isTotal 
              ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)
              : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
