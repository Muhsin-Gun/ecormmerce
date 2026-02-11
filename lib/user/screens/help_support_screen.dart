import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/support_utils.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        children: [
          // Search Support
          TextField(
            decoration: InputDecoration(
              hintText: 'Search help articles...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Frequently Asked Questions',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildFAQTile(
            context,
            question: 'How do I track my order?',
            answer: 'You can track your order in the "My Orders" section of your profile. Tap on any active order to see its current status and tracking information.',
          ),
          _buildFAQTile(
            context,
            question: 'What is your return policy?',
            answer: 'We offer a 30-day return policy for most items. Items must be in their original condition and packaging. Visit the returns page for more details.',
          ),
          _buildFAQTile(
            context,
            question: 'How can I change my payment method?',
            answer: 'Go to your Profile -> Payment Methods to add, remove, or change your default payment options securely.',
          ),
          _buildFAQTile(
            context,
            question: 'Is my data secure?',
            answer: 'ProMarket uses industry-standard encryption and security protocols to ensure your personal and payment data is always protected.',
          ),
          
          const SizedBox(height: 32),
          Text(
            'Need more help?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildContactCard(
            context,
            title: 'Chat with Support',
            subtitle: 'Get instant help from our team',
            icon: Icons.chat_outlined,
            color: AppColors.neonBlue,
            onTap: () {
              SupportUtils.startSupportChat(context);
            },
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            title: 'Email Us',
            subtitle: 'support@promarket.com',
            icon: Icons.email_outlined,
            color: AppColors.electricPurple,
            onTap: () {
              // Open email client
            },
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            title: 'Call Support',
            subtitle: '+1 (800) 123-4567',
            icon: Icons.phone_outlined,
            color: AppColors.success,
            onTap: () {
              // Open phone dialer
            },
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Text(
              'ProMarket Support v1.0.0',
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, {required String question, required String answer}) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: AppColors.gray500, height: 1.5)),
        ),
      ],
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      tilePadding: EdgeInsets.zero,
    );
  }

  Widget _buildContactCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
