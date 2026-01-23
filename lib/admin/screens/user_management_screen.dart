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
          queryBuilder: (q) => q.orderBy('createdAt', descending: true),
        ),
        builder: (context, snapshot) {
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
              final isApproved = user['isApproved'] ?? false;
              final email = user['email'] ?? '';
              final name = user['name'] ?? 'Unknown';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isApproved && (role == 'employee' || role == 'admin')) 
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: Text(
                               'PENDING APPROVAL',
                               style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                             ),
                           ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'approve') _updateUser(userId, {'isApproved': true});
                    if (value == 'revoke') _updateUser(userId, {'isApproved': false});
                    if (value == 'make_admin') _updateUser(userId, {'role': 'admin'});
                    if (value == 'make_employee') _updateUser(userId, {'role': 'employee'});
                    if (value == 'make_user') _updateUser(userId, {'role': 'user'});
                  },
                  itemBuilder: (context) => [
                    if (!isApproved) 
                       const PopupMenuItem(value: 'approve', child: Text('Approve Access')),
                    if (isApproved)
                       const PopupMenuItem(value: 'revoke', child: Text('Revoke Access')),
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

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseService.instance.updateDocument('users', userId, data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return AppColors.roleAdmin;
      case 'employee': return AppColors.roleEmployee;
      default: return AppColors.roleUser;
    }
  }
}
