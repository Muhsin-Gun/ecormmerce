import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/cart_item_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/cart_item_widget.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const CartScreen({super.key, this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Selector<CartProvider, bool>(
        selector: (_, cart) => cart.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) return const Center(child: CircularProgressIndicator());
          return Selector<CartProvider, int>(
            selector: (_, cart) => cart.items.length,
            builder: (context, itemCount, __) {
              if (itemCount == 0) {
                return _EmptyCart(onStartShopping: onStartShopping);
              }
              return Column(
                children: [
                  const Expanded(child: _CartItemsList()),
                  _CartSummary(theme: theme),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const _EmptyCart({this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: () {
              if (onStartShopping != null) {
                onStartShopping!();
                return;
              }
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  const _CartItemsList();

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, List<CartItemModel>>(
      selector: (_, cart) => cart.items,
      builder: (context, items, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Hero(
                tag: 'cart_item_${item.productId}',
                child: CartItemWidget(
                  item: item,
                  onIncrement: () => context
                      .read<CartProvider>()
                      .updateQuantity(item.productId, item.quantity + 1),
                  onDecrement: () => context
                      .read<CartProvider>()
                      .updateQuantity(item.productId, item.quantity - 1),
                  onRemove: () => context.read<CartProvider>().removeItem(item.productId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CartSummary extends StatelessWidget {
  final ThemeData theme;

  const _CartSummary({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cart.couponCode == null)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Coupon code',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (value) => cart.applyCoupon(value),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => AppFeedback.info(
                      context,
                      'Try WELCOME for 10% off.',
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Coupon: ${cart.couponCode}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 10),
            _summaryRow('Subtotal', Formatters.formatCurrency(cart.subtotal), theme),
            if (cart.discount > 0)
              _summaryRow(
                'Discount',
                '-${Formatters.formatCurrency(cart.discountAmount)}',
                theme,
                color: AppColors.success,
              ),
            const Divider(height: 20),
            _summaryRow('Total', Formatters.formatCurrency(cart.total), theme, isTotal: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Secure Checkout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, ThemeData theme,
      {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                : theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryIndigo,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
          ),
        ],
      ),
    );
  }
}
