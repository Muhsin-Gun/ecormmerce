import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final bool initialEmailSent;
  final String? pendingEmail;
  final String? pendingName;
  final String? pendingPhone;
  final String? pendingRole;

  const EmailVerificationScreen({
    super.key,
    this.initialEmailSent = false,
    this.pendingEmail,
    this.pendingName,
    this.pendingPhone,
    this.pendingRole,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _canResendEmail = false;
  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    if (widget.initialEmailSent) {
      // Enable resend after 60 seconds when we just sent an email.
      _startCountdown();
    } else {
      _canResendEmail = true;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _resolveDisplayEmail(AuthProvider authProvider) {
    final candidates = [
      widget.pendingEmail,
      authProvider.firebaseUser?.email,
      authProvider.userModel?.email,
      authProvider.pendingVerificationEmail,
    ];

    for (final candidate in candidates) {
      final value = (candidate ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return 'your email';
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

  Future<void> _checkEmailVerified({bool showPendingMessage = true}) async {
    final authProvider = context.read<AuthProvider>();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final isVerified = await authProvider.refreshEmailVerificationState();

      if (!isVerified) {
        if (mounted && showPendingMessage) {
          AppFeedback.info(
            context,
            'Email not verified yet. Please check your inbox and click the verification link.',
          );
        }
        return;
      }

      final completed = await authProvider.completeEmailVerifiedSignup(
        fallbackName: widget.pendingName,
        fallbackPhone: widget.pendingPhone,
        fallbackRole: widget.pendingRole,
      );
      if (!completed) {
        if (mounted) {
          AppFeedback.error(
            context,
            authProvider.errorMessage ?? 'Unable to complete account setup.',
            nextStep: 'Please retry.',
          );
        }
        return;
      }

      _countdownTimer?.cancel();
      await authProvider.signOut();
      if (!mounted) return;

      AppFeedback.success(
        context,
        'Email verified. Your account is ready. Please sign in.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          'Error verifying email. Please try again.',
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendEmailVerification();

    if (success && mounted) {
      AppFeedback.success(context, 'Verification email sent!');
      _startCountdown();
    } else if (mounted && authProvider.errorMessage != null) {
      AppFeedback.error(
        context,
        authProvider.errorMessage!,
        nextStep: 'Retry in a moment.',
      );
    }
  }

  Future<void> _logoutToLogin() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayEmail = _resolveDisplayEmail(authProvider);
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark
        ? AppColors.electricPurple.withValues(alpha: 0.3)
        : AppColors.primaryIndigo.withValues(alpha: 0.12);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logoutToLogin,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF090F1E),
                    Color(0xFF111B34),
                    Color(0xFF1A2B4B),
                  ]
                : const [
                    Color(0xFFF6F8FF),
                    Color(0xFFEDF3FF),
                    Color(0xFFEAF8FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [
                                    AppColors.primaryIndigoLight,
                                    AppColors.electricPurple,
                                  ]
                                : const [
                                    AppColors.primaryIndigo,
                                    AppColors.electricPurple,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricPurple.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text(
                        'Confirm Your Email',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Open your inbox and verify this email, then tap "I\'ve Verified My Email" to finish account setup.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.gray300 : AppColors.gray700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.gray800.withValues(alpha: 0.45)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isDark ? AppColors.gray700 : AppColors.gray300,
                          ),
                        ),
                        child: Text(
                          displayEmail,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.electricPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.autorenew_rounded,
                              size: 18,
                              color: AppColors.infoDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your profile will be created after verification is confirmed.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.gray200
                                      : AppColors.gray700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Column(
                            children: [
                              AuthButton(
                                text: 'I\'ve Verified My Email',
                                onPressed: () => _checkEmailVerified(),
                                isLoading: auth.isLoading,
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              TextButton(
                                onPressed: _canResendEmail
                                    ? _resendVerificationEmail
                                    : null,
                                child: Text(
                                  _canResendEmail
                                      ? 'Resend Verification Email'
                                      : 'Resend in ${_countdown}s',
                                  style: TextStyle(
                                    color: _canResendEmail
                                        ? AppColors.electricPurple
                                        : AppColors.gray500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
            ),
          ),
        ),
      ),
    );
  }
}
