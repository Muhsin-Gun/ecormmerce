import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../services/admin_user_service.dart';
import '../../shared/services/firebase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              AppTheme.spacingM,
              AppTheme.spacingM,
              AppTheme.spacingS,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, role, or status',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppFeedback.friendlyError(
                            snapshot.error ?? 'Could not load users.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please retry.',
                          style: TextStyle(color: AppColors.gray500),
                        ),
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

                final filteredUsers = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final user = doc.data() as Map<String, dynamic>;
                  final role =
                      (user['role'] ?? 'user').toString().toLowerCase();
                  final roleStatus =
                      (user['roleStatus'] ?? AppConstants.roleStatusPending)
                          .toString()
                          .toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  final name = (user['name'] ?? '').toString().toLowerCase();
                  final haystack = '$name $email $role $roleStatus';
                  return haystack.contains(_searchQuery);
                }).toList()
                  ..sort((a, b) {
                    final userA = a.data() as Map<String, dynamic>;
                    final userB = b.data() as Map<String, dynamic>;
                    final nameA =
                        (userA['name'] ?? '').toString().trim().toLowerCase();
                    final nameB =
                        (userB['name'] ?? '').toString().trim().toLowerCase();
                    return nameA.compareTo(nameB);
                  });

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No users match your search'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    final userId = filteredUsers[index].id;
                    final role = user['role'] ?? 'user';
                    final roleStatus =
                        user['roleStatus'] ?? AppConstants.roleStatusPending;
                    final email = user['email'] ?? '';
                    final name = user['name'] ?? 'Unknown';
                    final normalizedEmail = email.toString().toLowerCase();
                    final isSuperAdminUser = normalizedEmail ==
                        AppConstants.superAdminEmail.toLowerCase();
                    final isCurrentUser =
                        userId == FirebaseService.instance.currentUserId;

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
                              _buildBadge(
                                role.toUpperCase(),
                                _getRoleColor(role),
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                roleStatus.toUpperCase(),
                                _getStatusColor(roleStatus),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'approve') {
                            _updateUser(userId, {
                              'roleStatus': AppConstants.roleStatusApproved,
                            });
                          }
                          if (value == 'suspend') {
                            _updateUser(userId, {
                              'roleStatus': AppConstants.roleStatusSuspended,
                            });
                          }
                          if (value == 'reject') {
                            _updateUser(userId, {
                              'roleStatus': AppConstants.roleStatusRejected,
                            });
                          }
                          if (value == 'make_admin') {
                            _updateUser(
                                userId, {'role': AppConstants.roleAdmin});
                          }
                          if (value == 'make_employee') {
                            _updateUser(
                              userId,
                              {'role': AppConstants.roleEmployee},
                            );
                          }
                          if (value == 'make_user') {
                            _updateUser(
                                userId, {'role': AppConstants.roleClient});
                          }
                          if (value == 'delete') {
                            _confirmDeleteUser(userId, name);
                          }
                        },
                        itemBuilder: (context) => [
                          if (roleStatus != AppConstants.roleStatusApproved)
                            const PopupMenuItem(
                              value: 'approve',
                              child: Text('Approve / Activate'),
                            ),
                          if (roleStatus != AppConstants.roleStatusSuspended)
                            const PopupMenuItem(
                              value: 'suspend',
                              child: Text('Suspend Account'),
                            ),
                          if (roleStatus != AppConstants.roleStatusRejected &&
                              roleStatus == AppConstants.roleStatusPending)
                            const PopupMenuItem(
                              value: 'reject',
                              child: Text('Reject Application'),
                            ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Text('Promote to Admin'),
                          ),
                          const PopupMenuItem(
                            value: 'make_employee',
                            child: Text('Set to Employee'),
                          ),
                          const PopupMenuItem(
                            value: 'make_user',
                            child: Text('Demote to User'),
                          ),
                          if (!isSuperAdminUser && !isCurrentUser) ...[
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete User',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
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
        AppFeedback.success(context, 'User updated');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Could not update user.',
          nextStep: 'Please retry.',
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete $name permanently from authentication and Firestore? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteUser(userId);
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await AdminUserService.instance.deleteUserCompletely(userId);
      if (mounted) {
        AppFeedback.success(context, 'User deleted');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Could not delete user.',
          nextStep: 'Ensure cloud functions are deployed, then retry.',
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.roleAdmin;
      case 'employee':
        return AppColors.roleEmployee;
      default:
        return AppColors.roleUser;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.roleStatusApproved:
        return AppColors.success;
      case AppConstants.roleStatusPending:
        return AppColors.warning;
      case AppConstants.roleStatusSuspended:
        return AppColors.error;
      case AppConstants.roleStatusRejected:
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }
}
