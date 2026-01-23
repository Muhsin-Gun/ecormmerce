import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  Timer? _timer;
  bool _canResendEmail = false;
  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    // Check verification status periodically
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
    
    // Enable resend after 60 seconds
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResendEmail = false;
    _countdown = 60;
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.reloadUser();
    
    if (authProvider.isEmailVerified) {
      _timer?.cancel();
      setState(() => _isEmailVerified = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigation is handled by AuthWrapper
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendEmailVerification();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent!'),
          backgroundColor: AppColors.success,
        ),
      );
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              Text(
                'Verify your email address',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              Text(
                'We have sent a verification email to:\n${context.read<AuthProvider>().userModel?.email ?? "your email"}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),
              
              Text(
                'Click the link in the email to verify your account. If you don\'t see it, check your spam folder.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.gray500 : AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    children: [
                      AuthButton(
                        text: 'I\'ve Verified My Email',
                        onPressed: _checkEmailVerified,
                        isLoading: auth.isLoading,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      TextButton(
                        onPressed: _canResendEmail ? _resendVerificationEmail : null,
                        child: Text(
                          _canResendEmail 
                              ? 'Resend Email' 
                              : 'Resend in ${_countdown}s',
                          style: TextStyle(
                            color: _canResendEmail 
                                ? AppColors.electricPurple 
                                : AppColors.gray500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
