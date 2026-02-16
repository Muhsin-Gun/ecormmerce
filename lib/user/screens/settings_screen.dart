import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable a darker color scheme'),
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.setThemeMode,
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.electricPurple,
            ),
          ),
          
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts about orders and messages'),
            value: user?.notificationsEnabled ?? true,
            onChanged: (value) {
              // Update user notification preferences
              if (user != null) {
                authProvider.updateProfile(user.copyWith(notificationsEnabled: value));
              }
            },
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.electricPurple,
            ),
          ),
          
          _buildSectionHeader(context, 'About ProMarket'),
          ListTile(
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
            leading: const Icon(Icons.info_outline, color: AppColors.gray500),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            leading: const Icon(Icons.description_outlined, color: AppColors.gray500),
            onTap: () {
              // Open TOS URL
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.gray500),
            onTap: () {
              // Open Privacy Policy URL
            },
          ),
          
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out'),
            subtitle: const Text('End this session on this device'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.signOut();
                        Navigator.pop(context); // Close settings
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacingL, AppTheme.spacingL, AppTheme.spacingL, AppTheme.spacingS),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.gray500,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
