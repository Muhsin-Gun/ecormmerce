import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppFeedback {
  AppFeedback._();

  static void success(
    BuildContext context,
    String message, {
    String? semanticLabel,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.successDark,
      icon: Icons.check_circle_outline,
      semanticLabel: semanticLabel,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? semanticLabel,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.infoDark,
      icon: Icons.info_outline,
      semanticLabel: semanticLabel,
    );
  }

  static void error(
    BuildContext context,
    Object error, {
    String? fallbackMessage,
    String? nextStep,
    String? semanticLabel,
  }) {
    final base = friendlyError(error, fallbackMessage: fallbackMessage);
    final text = nextStep == null ? base : '$base $nextStep';
    _show(
      context,
      message: text,
      backgroundColor: AppColors.errorDark,
      icon: Icons.error_outline,
      semanticLabel: semanticLabel,
    );
  }

  static String friendlyError(Object error, {String? fallbackMessage}) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'network-request-failed':
        case 'unavailable':
          return 'Network issue. Check your connection and retry.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Sign-in was cancelled.';
        default:
          return error.message ?? fallbackMessage ?? 'Something went wrong.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'not-found':
          return 'Requested item was not found.';
        case 'unavailable':
          return 'Service is temporarily unavailable.';
        default:
          return error.message ?? fallbackMessage ?? 'Something went wrong.';
      }
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty || raw.toLowerCase().contains('firebase')) {
      return fallbackMessage ?? 'Something went wrong. Please try again.';
    }
    return raw;
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    String? semanticLabel,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        content: Semantics(
          liveRegion: true,
          label: semanticLabel ?? message,
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
