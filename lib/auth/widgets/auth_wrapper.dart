import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/constants.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../employee/screens/employee_dashboard_screen.dart';
import '../../user/screens/user_main_screen.dart';
import '../screens/login_screen.dart';
import '../../core/theme/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) return const LoginScreen();

        final user = snapshot.data!;
        final email = user.email ?? '';

        // 🚨 SUPER ADMIN ALWAYS ENTERS
        if (email.toLowerCase() == AppConstants.superAdminEmail.toLowerCase()) {
          return const AdminDashboardScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snap.hasData || !snap.data!.exists) {
              return const LoginScreen();
            }

            final userModel = UserModel.fromFirestore(snap.data!);

            // 🚨 SUPER ADMIN BYPASSES EMAIL VERIFICATION
            if (userModel.isRoot) {
              return const AdminDashboardScreen();
            }

            if (!userModel.emailVerified) {
              Future.microtask(() => FirebaseAuth.instance.signOut());
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Check if admin is approved (Root is always approved)
            if (userModel.role == 'admin' &&
                !userModel.isApproved &&
                !userModel.isRoot) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_empty,
                            size: 80, color: AppColors.warning),
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
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (userModel.role == 'admin') {
              return const AdminDashboardScreen();
            } else if (userModel.role == 'employee') {
              return const EmployeeDashboardScreen();
            }

            return const UserMainScreen();
          },
        );
      },
    );
  }
}
