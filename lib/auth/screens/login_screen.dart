import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'email_otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGoogleLoading = false;
  String? _oauthInlineError;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.slow,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final success = await authProvider.login(
      email: email,
      password: _passwordController.text,
    );
    
    if (success && mounted) {
      AppFeedback.success(context, 'Welcome back!');
      return;
    }

    if (!mounted) return;

    final pendingEmail = authProvider.pendingVerificationEmail;
    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      final pendingName = authProvider.pendingVerificationName ?? '';
      bool otpSent = false;
      try {
        otpSent = await authProvider
            .sendOTPtoEmail(
              email: pendingEmail,
              userName: pendingName,
            )
            .timeout(const Duration(seconds: 12));
      } on TimeoutException {
        otpSent = false;
      }
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmailOTPVerificationScreen(
            email: pendingEmail,
            userName: pendingName,
            initialCodeSent: otpSent,
          ),
        ),
      );
      return;
    }

    if (authProvider.errorMessage != null) {
      AppFeedback.error(
        context,
        authProvider.errorMessage!,
        nextStep: 'Please retry.',
      );
    }
  }

  Future<void> _signInWithGoogle({bool useAnotherAccount = false}) async {
    if (_isGoogleLoading) return;

    final auth = context.read<AuthProvider>();
    setState(() {
      _isGoogleLoading = true;
      _oauthInlineError = null;
    });

    try {
      if (useAnotherAccount) {
        await auth.logVerificationEvent(
          eventName: 'oauth_switch_account',
          email: _emailController.text.trim().isEmpty
              ? 'unknown@example.com'
              : _emailController.text.trim(),
        );
        await auth.prepareGoogleAccountSwitch();
      }

      final success = await auth
          .signInWithGoogle(
            forceAccountChooser: useAnotherAccount,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (success) {
        AppFeedback.success(context, 'Welcome! Signed in with Google');
      } else {
        final msg = auth.errorMessage ??
            'Could not complete Google sign-in. Retry or use another account.';
        final isCanceled = msg.toLowerCase().contains('canceled') ||
            msg.toLowerCase().contains('cancelled');
        setState(() {
          _oauthInlineError = msg;
        });
        if (isCanceled) {
          AppFeedback.info(context, 'Google sign-in was canceled.');
        } else {
          AppFeedback.error(context, msg);
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _oauthInlineError =
            'Google sign-in is taking too long. Please check your connection and try again.';
      });
      AppFeedback.error(context, _oauthInlineError!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _oauthInlineError = AppFeedback.friendlyError(e);
      });
      AppFeedback.error(
        context,
        _oauthInlineError!,
        nextStep: 'Retry or choose another account.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: double.infinity,
        decoration: isDark ? const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkNavy, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ) : null,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.electricPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: AppColors.electricPurple,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Welcome Text
                        Text(
                          'Welcome Back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Sign in to your account',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.gray400 : AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXL),
                        
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AuthTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              AuthTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: (value) => Validators.validateRequired(
                                  value, 
                                  fieldName: 'Password'
                                ),
                                onFieldSubmitted: (_) => _login(),
                              ),
                              
                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              
                              const SizedBox(height: AppTheme.spacingL),
                              
                              // Login Button
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Column(
                                    children: [
                                      AuthButton(
                                        text: 'Sign In',
                                        onPressed: _login,
                                        isLoading: auth.isLoading,
                                      ),
                                      
                                      const SizedBox(height: AppTheme.spacingL),
                                      
                                      // Divider with "Or"
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: isDark ? AppColors.gray600 : AppColors.gray300,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                                            child: Text(
                                              'Or continue with',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark ? AppColors.gray500 : AppColors.gray600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: isDark ? AppColors.gray600 : AppColors.gray300,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: AppTheme.spacingL),
                                      
                                       // Google Sign-In Button (Standard Design)
                                       SizedBox(
                                         width: double.infinity,
                                         height: 56,
                                         child: OutlinedButton(
                                          onPressed: (auth.isLoading || _isGoogleLoading)
                                              ? null
                                              : _signInWithGoogle,
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                                            side: BorderSide(
                                              color: isDark ? AppColors.gray600 : AppColors.gray300,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Google Icon (Simple)
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.1),
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'G',
                                                    style: TextStyle(
                                                      color: Color(0xFF4285F4),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Product Sans',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Google',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.white : AppColors.gray700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                       ),
                                      const SizedBox(height: AppTheme.spacingM),
                                      if (_oauthInlineError != null)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(AppTheme.spacingM),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.error),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _oauthInlineError!,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                children: [
                                                  TextButton(
                                                    onPressed: _isGoogleLoading
                                                        ? null
                                                        : _signInWithGoogle,
                                                    child: const Text('Retry'),
                                                  ),
                                                  TextButton(
                                                    onPressed: _isGoogleLoading
                                                        ? null
                                                        : () => _signInWithGoogle(
                                                            useAnotherAccount: true),
                                                    child: const Text('Sign in with another account'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_oauthInlineError == null)
                                        TextButton(
                                          onPressed: _isGoogleLoading
                                              ? null
                                              : () => _signInWithGoogle(
                                                    useAnotherAccount: true,
                                                  ),
                                          child: const Text('Sign in with another account'),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXL),
                        
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.gray400 : AppColors.gray600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.electricPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
