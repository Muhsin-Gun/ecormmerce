import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/firebase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.instance.getCollectionStream(
          'users',
          // removed orderBy to ensure all users show up even if createdAt is missing
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading users: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final role = user['role'] ?? 'user';
              final roleStatus = user['roleStatus'] ?? AppConstants.roleStatusPending;
              final email = user['email'] ?? '';
              final name = user['name'] ?? 'Unknown';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name.isNotEmpty ? name : 'No Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadge(role.toUpperCase(), _getRoleColor(role)),
                        const SizedBox(width: 8),
                        _buildBadge(roleStatus.toUpperCase(), _getStatusColor(roleStatus)),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'approve') _updateUser(userId, {'roleStatus': AppConstants.roleStatusApproved});
                    if (value == 'suspend') _updateUser(userId, {'roleStatus': AppConstants.roleStatusSuspended});
                    if (value == 'reject') _updateUser(userId, {'roleStatus': AppConstants.roleStatusRejected});
                    if (value == 'make_admin') _updateUser(userId, {'role': AppConstants.roleAdmin});
                    if (value == 'make_employee') _updateUser(userId, {'role': AppConstants.roleEmployee});
                    if (value == 'make_user') _updateUser(userId, {'role': AppConstants.roleClient});
                  },
                  itemBuilder: (context) => [
                    if (roleStatus != AppConstants.roleStatusApproved) 
                       const PopupMenuItem(value: 'approve', child: Text('Approve / Activate')),
                    if (roleStatus != AppConstants.roleStatusSuspended)
                       const PopupMenuItem(value: 'suspend', child: Text('Suspend Account')),
                    if (roleStatus != AppConstants.roleStatusRejected && roleStatus == AppConstants.roleStatusPending)
                       const PopupMenuItem(value: 'reject', child: Text('Reject Application')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'make_admin', child: Text('Promote to Admin')),
                    const PopupMenuItem(value: 'make_employee', child: Text('Set to Employee')),
                    const PopupMenuItem(value: 'make_user', child: Text('Demote to User')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseService.instance.updateDocument('users', userId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return AppColors.roleAdmin;
      case 'employee': return AppColors.roleEmployee;
      default: return AppColors.roleUser;
    }
  }
  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.roleStatusApproved: return AppColors.success;
      case AppConstants.roleStatusPending: return AppColors.warning;
      case AppConstants.roleStatusSuspended: return AppColors.error;
      case AppConstants.roleStatusRejected: return AppColors.gray500;
      default: return AppColors.gray500;
    }
  }
}
