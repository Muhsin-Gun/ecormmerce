import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(seconds: 2),
       vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               // Success Icon with Scale Animation
               ScaleTransition(
                 scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                 child: Container(
                   width: 120,
                   height: 120,
                   decoration: const BoxDecoration(
                     color: AppColors.success,
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.check, size: 64, color: Colors.white),
                 ),
               ),
               const SizedBox(height: AppTheme.spacingL),
               
               const Text(
                 'Order Placed Successfully!',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: AppTheme.spacingS),
               const Text(
                 'Thank you for your purchase. Your order is being processed.',
                 style: TextStyle(color: AppColors.gray600, fontSize: 16),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: AppTheme.spacingXL),

               ElevatedButton(
                 onPressed: () {
                    // Navigate to Order History
                    // Since specific route structure might vary, we can pop to home or push replace
                    Navigator.of(context).popUntil((route) => route.isFirst);
                 }, 
                 style: ElevatedButton.styleFrom(
                   minimumSize: const Size(200, 50),
                   backgroundColor: AppColors.primaryIndigo,
                   foregroundColor: Colors.white,
                 ),
                 child: const Text('Continue Shopping'),
               ),
               const SizedBox(height: AppTheme.spacingM),
               TextButton(
                 onPressed: () {
                   // Ideally navigate directly to Order History tab
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // Open dashboard? (Implementation detail)
                 },
                 child: const Text('View Order Status'),
               ),
             ],
          ),
        ),
      ),
    );
  }
}
