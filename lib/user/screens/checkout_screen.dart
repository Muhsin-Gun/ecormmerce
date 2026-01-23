import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/auth_text_field.dart';
import 'order_success_screen.dart';
import '../../shared/services/mpesa_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _paymentPhoneController = TextEditingController();
  
  // State
  String _paymentMethod = AppConstants.paymentMethodMpesa;
  bool _isLoading = false;
  
  // Costs
  final double _deliveryFee = 250.0; // Standard fee

  @override
  void initState() {
    super.initState();
    // Pre-fill user data
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _paymentPhoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final cart = context.read<CartProvider>();
      final auth = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      
      // 1. Create Address Data
      final address = AddressData(
        fullName: _nameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        streetAddress: _streetController.text,
        isDefault: true,
      );
      
      // 2. Create Order
      final orderId = await orderProvider.createOrder(
        userId: auth.firebaseUser!.uid,
        userName: auth.userModel?.name ?? _nameController.text,
        userPhone: _paymentPhoneController.text, // Use payment phone for MPESA
        cartItems: cart.items,
        deliveryAddress: address,
        subtotal: cart.subtotal,
        discount: cart.discountAmount,
        deliveryFee: _deliveryFee,
        couponCode: cart.couponCode,
      );
      
      if (orderId != null && mounted) {
        // 3. Trigger MPESA STK Push
        if (_paymentMethod == AppConstants.paymentMethodMpesa) {
          _showProcessingDialog(context);
          
          final result = await MpesaService.instance.initiateStkPush(
            phoneNumber: _paymentPhoneController.text,
            amount: 1.0, // Use 1.0 for testing, in prod use: (cart.total + _deliveryFee)
            accountReference: "Order ${orderId.substring(0,6)}",
            transactionDesc: "Payment for Order #${orderId.substring(0,6)}",
          );

          Navigator.pop(context); // Close dialog

          if (result['success'] == true) {
            final checkoutRequestId = result['checkoutRequestID'];
            
            // Show "Check Phone" Dialog
             await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Check your Phone'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android, size: 48, color: AppColors.electricPurple),
                    const SizedBox(height: 16),
                    const Text('Please enter your M-PESA PIN to complete the payment.'),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Waiting for confirmation...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // In a real app we might keep polling longer or verify later
                      // For now, proceed to success assuming they paid or will pay
                    },
                    child: const Text('I have Paid'),
                  ),
                ],
              ),
            );

            // Here we would ideally poll the status -> MpesaService.queryTransactionStatus
            // For UI flow, we proceed:
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Failed: ${result['error']}')),
            );
            // Optionally cancel order or let them retry
            return;
          }
        }
        
        // Clear Cart
        await cart.clearCart();
        
        // Navigate to Success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: orderId),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Checkout Error: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.electricPurple),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep == 0) {
                // Validate address step
                if (_nameController.text.isNotEmpty && 
                    _phoneController.text.isNotEmpty && 
                    _cityController.text.isNotEmpty && 
                    _streetController.text.isNotEmpty) {
                  setState(() => _currentStep++);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all address fields')),
                  );
                }
              } else if (_currentStep == 1) {
                setState(() => _currentStep++);
              } else {
                _placeOrder();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: AuthButton(
                        text: _currentStep == 2 ? 'Place Order' : 'Continue',
                        onPressed: details.onStepContinue,
                        isLoading: _isLoading,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.gray500),
                          ),
                          child: const Text('Back', style: TextStyle(color: AppColors.gray600)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Address
              Step(
                title: const Text('Address'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.editing,
                content: Column(
                  children: [
                    AuthTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      hintText: 'Receiver Name',
                      prefixIcon: Icons.person_outline,
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Contact number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                     const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _cityController,
                            labelText: 'City/Town',
                            prefixIcon: Icons.location_city,
                            validator: Validators.validateRequired,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AuthTextField(
                            controller: _streetController,
                            labelText: 'Street/Estate',
                            prefixIcon: Icons.map_outlined,
                            validator: Validators.validateRequired,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Step 2: Payment
              Step(
                title: const Text('Payment'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.editing,
                content: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.electricPurple),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.electricPurple.withOpacity(0.05),
                      ),
                      child: RadioListTile(
                        value: AppConstants.paymentMethodMpesa,
                        groupValue: _paymentMethod,
                        onChanged: (val) {},
                        title: const Text(
                          'M-PESA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Pay instantly to Till/Paybill'),
                        secondary: const Icon(Icons.phone_android, color: AppColors.electricPurple),
                        activeColor: AppColors.electricPurple,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Enter MPESA Number for Payment'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: _paymentPhoneController,
                      labelText: 'M-PESA Number',
                      hintText: '07...',
                      prefixIcon: Icons.sim_card,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You will receive an STK push on this number to complete the payment.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),

              // Step 3: Review
              Step(
                title: const Text('Review'),
                isActive: _currentStep >= 2,
                content: Column(
                  children: [
                    _buildSummaryRow(context, 'Subtotal', cart.subtotal),
                    if (cart.discount > 0)
                      _buildSummaryRow(context, 'Discount', -cart.discountAmount, isDiscount: true),
                    _buildSummaryRow(context, 'Delivery Fee', _deliveryFee),
                    const Divider(),
                    _buildSummaryRow(
                      context, 
                      'Total to Pay', 
                      cart.total + _deliveryFee, 
                      isTotal: true
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: AppColors.gray600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_cityController.text}, ${_streetController.text}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal 
                  ? AppColors.primaryIndigo 
                  : (isDiscount ? AppColors.success : null),
            ),
          ),
        ],
      ),
    );
  }
}
