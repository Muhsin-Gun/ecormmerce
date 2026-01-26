import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';

class RoleGuard extends StatelessWidget {
  final UserModel user;
  final List<String> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.user,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Root admin bypasses all role checks
    if (user.isRoot) return child;
    
    if (!allowedRoles.contains(user.role)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Your role (${user.role}) does not have permission to view this page.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
