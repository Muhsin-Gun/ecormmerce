import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_feedback.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Approvals'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppFeedback.friendlyError(
                    snapshot.error ?? 'Could not load approvals.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No pending admin approvals', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: AppColors.darkCard,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['email'] ?? 'No Email', style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Role: Admin', style: TextStyle(color: Colors.white54)),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await auth.approveAdmin(doc.id);
                      } catch (e) {
                        if (!context.mounted) return;
                        AppFeedback.error(
                          context,
                          e,
                          fallbackMessage: 'Could not approve admin.',
                          nextStep: 'Please retry.',
                        );
                        return;
                      }
                      if (context.mounted) {
                        AppFeedback.success(context, 'Admin approved successfully');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
