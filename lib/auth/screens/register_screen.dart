import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      final registrationResult = await authProvider.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: AppConstants.roleClient,
      );

      if (!mounted) return;

      // Registration failed - show error
      if (registrationResult == null) {
        final error = authProvider.errorMessage ?? '';

        // Check if email is already registered
        final isAlreadyRegistered =
            error.toLowerCase().contains('already registered');

        if (isAlreadyRegistered) {
          AppFeedback.info(
            context,
            'This email is already registered. Sign in with your password or reset it if you forgot.',
          );
          // Return to the root auth flow so AuthWrapper controls routing.
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        // Show other registration errors
        AppFeedback.error(
          context,
          error.isEmpty
              ? 'Unable to create your account. Please try again.'
              : error,
        );
        return;
      }

      // Registration successful - show the verification screen
      AppFeedback.success(
        context,
        'Verification email sent. Verify your email to finish creating your account.',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            initialEmailSent: true,
            pendingEmail: email,
            pendingName: name,
            pendingPhone: phone,
            pendingRole: AppConstants.roleClient,
          ),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      AppFeedback.error(
        context,
        'Sign up took too long. Check your internet connection and try again.',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        e,
        fallbackMessage: 'Unable to create account. Please try again.',
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: formContent(theme, isDark),
            ),
          ),
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
            prefixIcon: Icons.person_outline,
            validator: (value) => Validators.validateName(value),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AuthTextField(
            controller: _emailController,
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AuthTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
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
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            suffixIcon: _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixIconPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AuthTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixIconPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (value) => Validators.validatePasswordConfirmation(
                value, _passwordController.text),
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
          Text(
            'By continuing, you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
