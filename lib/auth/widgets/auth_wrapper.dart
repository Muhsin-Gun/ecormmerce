import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/screens/admin_dashboard_screen.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../employee/screens/employee_dashboard_screen.dart';
import '../../shared/widgets/first_run_permissions_gate.dart';
import '../../user/screens/user_main_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/email_verification_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUser = auth.firebaseUser;
    final userModel = auth.userModel;

    if (firebaseUser == null) return const LoginScreen();

    final firebaseVerified = firebaseUser.emailVerified;
    if (!firebaseVerified && (userModel == null || !userModel.emailVerified)) {
      return EmailVerificationScreen(
        pendingEmail: firebaseUser.email,
      );
    }

    if (auth.isLoading && userModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userModel == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 14),
                const Text('Syncing your account...'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: auth.reloadUser,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final email = (firebaseUser.email ?? '').toLowerCase();
    final isSuperAdmin = email == AppConstants.superAdminEmail.toLowerCase();
    if (isSuperAdmin || userModel.isRoot) {
      return const AdminDashboardScreen();
    }

    if (!userModel.emailVerified) {
      return const EmailVerificationScreen();
    }

    if (userModel.role == AppConstants.roleAdmin &&
        !userModel.isApproved &&
        !userModel.isRoot) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Approval Pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your admin account is pending approval by the root administrator. You will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userModel.role == AppConstants.roleAdmin) {
      return const AdminDashboardScreen();
    }
    if (userModel.role == AppConstants.roleEmployee) {
      return const EmployeeDashboardScreen();
    }

    return const FirstRunPermissionsGate(
      child: UserMainScreen(
        initialTabIndex: 0,
        restorePersistedTab: false,
      ),
    );
  }
}
