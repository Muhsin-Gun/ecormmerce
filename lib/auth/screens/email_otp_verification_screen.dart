import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../providers/auth_provider.dart';
import '../services/otp_policy.dart';
import 'login_screen.dart';

class EmailOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String userName;
  final bool initialCodeSent;

  const EmailOTPVerificationScreen({
    super.key,
    required this.email,
    required this.userName,
    this.initialCodeSent = true,
  });

  @override
  State<EmailOTPVerificationScreen> createState() =>
      _EmailOTPVerificationScreenState();
}

class _EmailOTPVerificationScreenState extends State<EmailOTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _requestTimeout =
      Duration(seconds: OtpPolicy.timeoutSeconds);

  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpVerified = false;
  String? _errorMessage;
  int _remainingSeconds = 0;
  bool _canResend = false;
  bool _expired = false;
  bool _cancelRequested = false;
  Timer? _timer;
  int _requestToken = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();

    if (widget.initialCodeSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AuthProvider>();
        _startCountdown(auth.otpCooldownSeconds);
      });
    } else {
      _remainingSeconds = 0;
      _canResend = true;
      _errorMessage = 'Code expired — resend?';
      _expired = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _canResend = seconds <= 0;
    });

    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _otpVerified) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _canResend = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'Enter the 6-digit code.';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = ++_requestToken;
    _cancelRequested = false;

    setState(() {
      _isLoading = true;
      _expired = false;
      _errorMessage = null;
    });

    _showLoadingDialog(
      onCancel: () {
        _cancelRequested = true;
        _requestToken++;
        authProvider.logVerificationEvent(
          eventName: 'otp_verify_cancel',
          email: widget.email,
        );
      },
    );

    try {
      final success = await authProvider
          .verifyOTP(
            email: widget.email,
            otp: _otpController.text.trim(),
          )
          .timeout(_requestTimeout);

      if (!mounted || token != _requestToken || _cancelRequested) return;

      Navigator.of(context, rootNavigator: true).maybePop();

      if (success) {
        setState(() {
          _otpVerified = true;
        });

        AppFeedback.success(context, 'Email verified successfully. Please sign in.');

        await Future.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        final msg = authProvider.errorMessage ?? 'Invalid verification code.';
        setState(() {
          _errorMessage = msg;
          _expired = msg.toLowerCase().contains('expired');
        });
      }
    } on TimeoutException {
      if (!mounted || token != _requestToken) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() {
        _errorMessage =
            'Verification is taking longer than expected. Retry or cancel.';
      });
      AppFeedback.error(context, _errorMessage!);
      await authProvider.logVerificationEvent(
        eventName: 'otp_verify_timeout',
        email: widget.email,
      );
    } catch (e) {
      if (!mounted || token != _requestToken) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      final msg = AppFeedback.friendlyError(e);
      setState(() {
        _errorMessage = msg;
        _expired = msg.toLowerCase().contains('expired');
      });
      AppFeedback.error(context, msg);
    } finally {
      if (mounted && token == _requestToken) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isLoading) return;

    final authProvider = context.read<AuthProvider>();
    final token = ++_requestToken;
    _cancelRequested = false;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _showLoadingDialog(
      onCancel: () {
        _cancelRequested = true;
        _requestToken++;
        authProvider.logVerificationEvent(
          eventName: 'otp_resend_cancel',
          email: widget.email,
        );
      },
    );

    try {
      final success = await authProvider
          .resendOTP(
            email: widget.email,
            userName: widget.userName,
          )
          .timeout(_requestTimeout);

      if (!mounted || token != _requestToken || _cancelRequested) return;
      Navigator.of(context, rootNavigator: true).maybePop();

      if (success) {
        _otpController.clear();
        final cooldown = authProvider.otpCooldownSeconds;
        _startCountdown(cooldown);
        setState(() {
          _expired = false;
        });
        AppFeedback.success(context, 'New code sent to ${widget.email}');
        await authProvider.logVerificationEvent(
          eventName: 'otp_resend_success',
          email: widget.email,
        );
      } else {
        final msg = authProvider.errorMessage ?? 'Unable to resend code.';
        setState(() {
          _errorMessage = msg;
        });
      }
    } on TimeoutException {
      if (!mounted || token != _requestToken) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() {
        _errorMessage =
            'Request timed out. Retry, or sign in with another account.';
      });
      AppFeedback.error(context, _errorMessage!);
      await authProvider.logVerificationEvent(
        eventName: 'otp_resend_timeout',
        email: widget.email,
      );
    } catch (e) {
      if (!mounted || token != _requestToken) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() {
        _errorMessage = AppFeedback.friendlyError(e);
      });
      AppFeedback.error(context, _errorMessage!);
    } finally {
      if (mounted && token == _requestToken) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _countdownText() => OtpPolicy.formatCountdownLabel(_remainingSeconds);

  void _showLoadingDialog({required VoidCallback onCancel}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Still loading… Cancel')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onCancel();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Request canceled. Retry when ready.';
                });
              }
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final resendCapReached = auth.otpResendCapReached;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXL),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _otpVerified
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.electricPurple.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          _otpVerified
                              ? Icons.check_circle
                              : Icons.mark_email_unread_outlined,
                          size: 60,
                          color: _otpVerified
                              ? AppColors.success
                              : AppColors.electricPurple,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      Text(
                        _otpVerified ? 'Email Verified' : 'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        _otpVerified
                            ? 'You can now sign in to your account.'
                            : 'Verification email sent to ${widget.email}. Didn’t receive it? Resend.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      if (!_otpVerified) ...[
                        TextFormField(
                          controller: _otpController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: theme.textTheme.displaySmall?.copyWith(
                              color:
                                  isDark ? AppColors.gray700 : AppColors.gray300,
                              letterSpacing: 8,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingL,
                              horizontal: AppTheme.spacingM,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _errorMessage != null
                                    ? AppColors.error
                                    : (isDark
                                        ? AppColors.gray700
                                        : AppColors.gray300),
                                width: _errorMessage != null ? 2 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.electricPurple,
                                width: 2,
                              ),
                            ),
                            counterText: '',
                            filled: true,
                            fillColor:
                                isDark ? AppColors.gray800 : AppColors.gray100,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = null;
                            });
                            if (value.trim().length == 6 && !_isLoading) {
                              _verifyOTP();
                            }
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                                if (_expired)
                                  TextButton(
                                    onPressed: _isLoading ? null : _resendOTP,
                                    child: const Text('Resend code'),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppTheme.spacingXL),
                        FilledButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingM),
                            backgroundColor: AppColors.electricPurple,
                            disabledBackgroundColor: AppColors.gray500,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Verify Code',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Semantics(
                          liveRegion: true,
                          label: _countdownText(),
                          child: Text(
                            _canResend ? 'Resend code' : _countdownText(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _canResend
                                  ? AppColors.electricPurple
                                  : AppColors.gray500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        TextButton(
                          onPressed: (_canResend && !_isLoading && !resendCapReached)
                              ? _resendOTP
                              : null,
                          child: const Text('Resend code'),
                        ),
                        if (resendCapReached)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Resend limit reached. Contact support or use alternate verification.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warningDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ] else ...[
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingM),
                            backgroundColor: AppColors.success,
                          ),
                          child: Text(
                            'Go to Login',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingL),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                        child: const Text('Sign in with another account'),
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
