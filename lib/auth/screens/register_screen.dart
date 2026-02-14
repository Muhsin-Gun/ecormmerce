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
import 'email_otp_verification_screen.dart';

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

    final success = await authProvider.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: AppConstants.roleClient,
    );

    if (success && mounted) {
      await authProvider.signOut();
      if (!mounted) return;

      final otpSent = await authProvider.sendOTPtoEmail(
        email: email,
        userName: name,
      );
      if (!mounted) return;

      if (otpSent) {
        AppFeedback.success(
          context,
          'Verification email sent to $email. Didn\'t receive it? Resend.',
        );
      } else {
        AppFeedback.error(
          context,
          authProvider.errorMessage ??
              'Could not send OTP automatically. Request another code.',
          nextStep: 'Use Resend code on the next screen.',
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EmailOTPVerificationScreen(
            email: email,
            userName: name,
            initialCodeSent: otpSent,
          ),
        ),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      AppFeedback.error(
        context,
        authProvider.errorMessage!,
        nextStep: 'Check your details and try again.',
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
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixIconPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (value) =>
                Validators.validatePasswordConfirmation(value, _passwordController.text),
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
