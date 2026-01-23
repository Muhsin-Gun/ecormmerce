import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/cart_item_widget.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Confirm Clear
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Are you sure you want to remove all items?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        context.read<CartProvider>().clearCart();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.electricPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: AppColors.electricPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Cart is Empty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Looks like you haven\'t added anything yet',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 32),
                  AuthButton(
                    text: 'Start Shopping',
                    width: 200,
                    onPressed: () {
                      Navigator.pop(context); // Go back to shop
                      // Or switch tab if needed via a callback or key
                    },
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemWidget(
                      item: item,
                      onIncrement: () => cart.incrementQuantity(item.productId),
                      onDecrement: () => cart.decrementQuantity(item.productId),
                      onRemove: () => cart.removeItem(item.productId),
                    );
                  },
                ),
              ),

              // Summary
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Coupon Field
                      Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: AppColors.gray500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: cart.couponCode != null
                                ? Text(
                                    'Coupon Applied: ${cart.couponCode} (${cart.discount.toInt()}% OFF)',
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                  )
                                : TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Enter Promo Code',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (value) async {
                                      if (value.isNotEmpty) {
                                         final success = await cart.applyCoupon(value);
                                         if (!success && context.mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Invalid coupon code')),
                                           );
                                         }
                                      }
                                    },
                                  ),
                          ),
                          if (cart.couponCode != null)
                             IconButton(
                               icon: const Icon(Icons.close, size: 18),
                               onPressed: () => cart.removeCoupon(),
                             )
                          else
                            TextButton(
                              onPressed: () {
                                // Trigger validation via controller or dialog
                              },
                              child: const Text('APPLY'),
                            ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // Totals
                      _buildSummaryRow(
                        context, 
                        'Subtotal', 
                        Formatters.formatCurrency(cart.subtotal),
                      ),
                       if (cart.discount > 0)
                        _buildSummaryRow(
                          context, 
                          'Discount', 
                          '-${Formatters.formatCurrency(cart.discountAmount)}',
                          isDiscount: true,
                        ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context, 
                        'Total', 
                        Formatters.formatCurrency(cart.total),
                        isBold: true,
                        isTotal: true,
                      ),
                      const SizedBox(height: 24),
                      
                      // Checkout Button
                      AuthButton(
                        text: 'Proceed to Checkout',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        },
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

  Widget _buildSummaryRow(
    BuildContext context, 
    String label, 
    String value, {
    bool isBold = false, 
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final color = isTotal 
        ? AppColors.primaryIndigo 
        : (isDiscount ? AppColors.success : null);
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 20 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
