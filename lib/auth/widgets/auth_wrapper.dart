import 'package:flutter/material.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../user/screens/user_dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/email_verification_screen.dart';
import '../screens/login_screen.dart';
import '../../core/theme/app_colors.dart';

/// Authentication Wrapper
/// Routes the user to the correct screen based on auth state and role status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 1. Check if loading
        if (auth.isLoading && auth.userModel == null) {
          return Scaffold(
            body: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.electricPurple),
              ),
            ),
          );
        }

        // 2. Check if authenticated
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final user = auth.userModel!;

        // 3. Check role status (Suspended/Rejected)
        if (user.isSuspended) {
          return _StatusScreen(
            icon: Icons.block,
            color: AppColors.error,
            title: 'Account Suspended',
            message: 'Your account has been suspended. Please contact support.',
            showLogout: true,
          );
        }

        if (user.isRejected) {
          return _StatusScreen(
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            title: 'Application Rejected',
            message: 'Your application has been rejected. Please contact support for more details.',
            showLogout: true,
          );
        }

        // 4. Check role status (Pending - for Employees/Admins)
        if (user.isPending) {
          return _StatusScreen(
            icon: Icons.hourglass_empty,
            color: AppColors.warning,
            title: 'Approval Pending',
            message: 'Your account is pending approval by an administrator. You will be notified once approved.',
            showLogout: true,
          );
        }

        // 5. Check email verification (For Clients mainly, but good for all)
        // Note: You might want to force verification only for clients if you auto-verify others
        if (!auth.isEmailVerified) {
          return const EmailVerificationScreen();
        }

        // 6. All good - Go to Dashboard
        if (user.isAdmin) {
          return const AdminDashboardScreen();
        } else if (user.isEmployee) {
          // return const EmployeeDashboardScreen();
        }
        
        return const UserDashboardScreen();
      },
    );
  }
}

/// Simple status screen for blocked/pending states
class _StatusScreen extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool showLogout;

  const _StatusScreen({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.showLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: color),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (showLogout) ...[
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
