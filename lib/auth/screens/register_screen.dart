import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selector.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State
  String _selectedRole = AppConstants.roleClient;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate role-specific rules if any
    if (_selectedRole == AppConstants.roleAdmin) {
      // In a real app, you might want to prevent direct admin registration
      // or require a secret code. For this demo, we'll allow it with a warning.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Admin Registration'),
          content: const Text(
            'Admin accounts require approval. Your account will be pending until approved by another admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }

    FocusScope.of(context).unfocus();
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );
    
    if (success && mounted) {
      // Navigate to email verification screen for all users
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
      
      if (_selectedRole != AppConstants.roleClient) {
        // Show dialog about pending approval if they chose employee/admin
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Created'),
            content: const Text(
              'Your account is created and pending approval. Please verify your email first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: formContent(theme, isDark),
        ),
      ),
    );
  }

  Widget formContent(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role Selection
          RoleSelector(
            selectedRole: _selectedRole,
            onRoleSelected: (role) {
              setState(() => _selectedRole = role);
            },
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          Text(
            'Personal Information',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          AuthTextField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: Icons.person_outline,
            validator: (value) => Validators.validateName(value),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          AuthTextField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'john@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          AuthTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
            hintText: '0712 345 678',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          Text(
            'Security',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          AuthTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Min 8 chars, 1 uppercase, 1 number',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          AuthTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixIconPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) => Validators.validatePasswordConfirmation(value, _passwordController.text),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return AuthButton(
                text: 'Create Account',
                onPressed: _register,
                isLoading: auth.isLoading,
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Terms text
          Text(
            'By continuing, you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.gray500 : AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
