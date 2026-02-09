import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/services/mpesa_service.dart';
import 'order_success_screen.dart';
import '../../shared/models/payment_model.dart';
import '../../core/utils/app_error_reporter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'MPESA';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      // Pre-fill if available (assuming user model has these fields in future)
      // _addressController.text = user.address ?? ''; 
      if (user.phoneNumber != null) _phoneController.text = user.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final cart = context.read<CartProvider>();
    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login before placing an order.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    
    // Create detailed order map
    final orderData = {
      'userId': user.uid,
      'userName': user.name,
      'userPhone': _phoneController.text,
      'items': cart.items.map((i) => i.toMap()).toList(),
      'total': cart.total,
      'subtotal': cart.subtotal,
      'discount': cart.discountAmount,
      'status': 'pending', 
      'paymentMethod': _selectedPaymentMethod,
      'paymentStatus': 'pending',
      'deliveryAddress': {
        'street': _addressController.text,
        'city': '',
        'label': 'Delivery',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // simulate network delay for UX
      // Save order to Firestore
      final orderDoc = await FirebaseService.instance.addDocument('orders', orderData);

      // Handle MPESA Payment Trigger
      // Handle MPESA Payment Trigger
      if (_selectedPaymentMethod == 'MPESA') {
         try {
           final mpesaResponse = await MpesaService.instance.initiateStkPush(
             phoneNumber: _phoneController.text,
             amount: cart.total,
             accountReference: orderDoc.id,
             transactionDesc: 'Payment for Order ${orderDoc.id}',
           );
           
           if (!mpesaResponse['success']) {
             await FirebaseService.instance.updateDocument(
               'orders',
               orderDoc.id,
               {
                 'paymentStatus': 'failed',
                 'updatedAt': DateTime.now().toIso8601String(),
               },
             );
             if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Payment initiation failed: ${mpesaResponse['error']}. Check API Keys.'),
                 backgroundColor: AppColors.error,
                 duration: const Duration(seconds: 5),
               ),
             );
             return;
           }

           await FirebaseService.instance.updateDocument(
             'orders',
             orderDoc.id,
             {
               'paymentStatus': 'processing',
               'mpesaCheckoutRequestId': mpesaResponse['checkoutRequestID'],
               'mpesaMerchantRequestId': mpesaResponse['merchantRequestID'],
               'mpesaPhoneNumber': _phoneController.text,
               'updatedAt': DateTime.now().toIso8601String(),
             },
           );
         } catch (e) {
           debugPrint('MPESA Error: $e');
           await AppErrorReporter.report(e, null);
           await FirebaseService.instance.updateDocument(
             'orders',
             orderDoc.id,
             {
               'paymentStatus': 'failed',
               'updatedAt': DateTime.now().toIso8601String(),
             },
           );
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('M-Pesa Error: $e. Check API Keys.'),
               backgroundColor: AppColors.error,
               duration: const Duration(seconds: 5),
             ),
           );
           return;
         }
      }

      // Create Pending Transaction Record
      try {
        await FirebaseService.instance.addDocument('transactions', {
          'orderId': orderDoc.id,
          'userId': user.uid,
          'amount': cart.total,
          'method': _selectedPaymentMethod,
          'status': 'pending', 
          'createdAt': FieldValue.serverTimestamp(),
          'mpesaPhoneNumber': _phoneController.text,
          'mpesaReceiptNumber': null,
          'mpesaTransactionId': null,
        });
      } catch (e) {
         debugPrint('Error creating transaction record: $e');
         await AppErrorReporter.report(e, null);
      }

      // Clear Cart
      await cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      await AppErrorReporter.report(e, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // 1. Delivery Details
              const SectionHeader(title: 'Delivery Details'),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  children: [
                    TextFormField(
                       controller: _phoneController,
                       keyboardType: TextInputType.phone,
                       decoration: const InputDecoration(
                         labelText: 'Phone Number (for MPESA payment)',
                         prefixIcon: Icon(Icons.phone),
                       ),
                       validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                       controller: _addressController,
                       maxLines: 2,
                       decoration: const InputDecoration(
                         labelText: 'Delivery Address',
                         prefixIcon: Icon(Icons.location_on),
                       ),
                       validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // 2. Payment Method
              const SectionHeader(title: 'Payment Method'),
              _buildPaymentOption('MPESA', 'M-Pesa (Mobile Money)', Icons.mobile_friendly, true),
              const SizedBox(height: AppTheme.spacingS),
              _buildPaymentOption('CASH', 'Cash on Delivery', Icons.money, false),
              const SizedBox(height: AppTheme.spacingL),

              // 3. Order Summary
              const SectionHeader(title: 'Order Summary'),
               Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppColors.gray200),
                ),
                 child: Column(
                   children: [
                     ...cart.items.take(3).map((item) => Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(child: Text('${item.quantity}x ${item.productName}', overflow: TextOverflow.ellipsis)),
                           Text(Formatters.formatCurrency(item.price * item.quantity)),
                         ],
                       ),
                     )),
                     if (cart.items.length > 3) 
                        Text('+ ${cart.items.length - 3} more items', style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                     const Divider(),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                         Text(Formatters.formatCurrency(cart.total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryIndigo, fontSize: 18)),
                       ],
                     ),
                   ],
                 ),
               ),
              const SizedBox(height: AppTheme.spacingXL),

              // Place Order
              AuthButton(
                text: 'Place Order',
                onPressed: _placeOrder,
                isLoading: _isLoading,
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon, bool isRecommended) {
    final isSelected = _selectedPaymentMethod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
             ? AppColors.electricPurple.withOpacity(0.1) 
             : (isDark ? AppColors.darkCard : Colors.white),
          border: Border.all(
             color: isSelected ? AppColors.electricPurple : AppColors.gray300,
             width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.electricPurple : AppColors.gray500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
                  if (isRecommended)
                    Text('Recommended', style: TextStyle(fontSize: 10, color: AppColors.success)),
                ],
              ),
            ),
            if (isSelected) 
               const Icon(Icons.check_circle, color: AppColors.electricPurple),
          ],
        ),
      ),
    );
  }
}
