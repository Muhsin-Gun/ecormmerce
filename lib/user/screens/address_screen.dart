import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          _buildAddressCard(
            context,
            label: 'Home',
            address: '123 Main St, Apartment 4B\nMombasa, Kenya',
            isDefault: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildAddressCard(
            context,
            label: 'Office',
            address: 'ProBusiness Center, 10th Floor\nNairobi, Kenya',
            isDefault: false,
          ),
          const SizedBox(height: AppTheme.spacingL),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, {required String label, required String address, required bool isDefault}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDefault ? AppColors.primaryIndigo : AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('DEFAULT', style: TextStyle(color: AppColors.primaryIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          const Divider(height: 24),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Edit')),
              TextButton(onPressed: () {}, child: const Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }
}
