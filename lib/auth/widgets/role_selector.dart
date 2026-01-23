import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Animated role selector for registration screen
/// Allows user to choose between Client, Employee, and Admin
class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your role',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRoleCard(
              context,
              role: AppConstants.roleClient,
              icon: Icons.person_outline,
              label: 'Shopper',
              color: AppColors.roleUser,
            ),
            const SizedBox(width: AppTheme.spacingM),
            _buildRoleCard(
              context,
              role: AppConstants.roleEmployee,
              icon: Icons.badge_outlined,
              label: 'Partner',
              color: AppColors.roleEmployee,
            ),
            const SizedBox(width: AppTheme.spacingM),
            _buildRoleCard(
              context,
              role: AppConstants.roleAdmin,
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              color: AppColors.roleAdmin,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedRole == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onRoleSelected(role),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.gray500,
                size: 28,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : AppColors.gray500,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
